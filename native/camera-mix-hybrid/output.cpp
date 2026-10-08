// Sunjoo OBS Link Controller / SunjooAn. SPDX-License-Identifier: GPL-2.0-or-later
#include <obs-module.h>
#include <mutex>
#include <cstring>
#include <algorithm>
#include <util/platform.h>

OBS_DECLARE_MODULE()
MODULE_EXPORT const char *obs_module_version(void) { return HYBRID_VERSION; }
MODULE_EXPORT uint32_t sunjoo_obs_link_contract(void) { return 2; }
MODULE_EXPORT const char *obs_module_name(void) { return "Sunjoo OBS Link Controller " HYBRID_VERSION; }
MODULE_EXPORT const char *obs_module_description(void) { return "Sunjoo OBS Link Controller clone-safe output / SunjooAn / " HYBRID_VERSION; }
MODULE_EXPORT const char *obs_module_author(void) { return "SunjooAn"; }

struct Output {
    obs_source_t *self;
    std::mutex mutex;
    obs_source_t *child = nullptr;
    bool frozen;
    bool continuing = false;
    float capturedTime = 0.0f;
    uint64_t capturedAt = 0;
    uint32_t duration = 300;
};
static obs_source_t *duplicate_camera(obs_source_t *target)
{
    if (obs_source_get_type(target) == OBS_SOURCE_TYPE_TRANSITION) {
        auto *active = obs_transition_get_active_source(target);
        auto *result = active ? duplicate_camera(active) : nullptr;
        obs_source_release(active);
        return result;
    }
    auto *copy = obs_source_duplicate(target, obs_source_get_name(target), true);
    if (copy && copy != target) {
        auto *meta = obs_source_get_private_settings(copy);
        auto *origin = obs_source_get_private_settings(target);
        const char *uuid = obs_data_get_string(origin, "camera_mix_hybrid_original_uuid");
        obs_data_set_string(meta, "camera_mix_hybrid_original_uuid", *uuid ? uuid : obs_source_get_uuid(target));
        obs_data_release(origin); obs_data_release(meta);
    }
    return copy;
}
static obs_source_t *active_fade(obs_source_t *source)
{
    if (!source) return nullptr;
    if (obs_source_get_type(source) == OBS_SOURCE_TYPE_TRANSITION &&
        !strcmp(obs_source_get_unversioned_id(source), "fade_transition")) return obs_source_get_ref(source);
    obs_source_t *result = nullptr;
    obs_source_enum_active_sources(source, [](obs_source_t *, obs_source_t *child, void *data) {
        auto **result = static_cast<obs_source_t **>(data);
        if (!*result && obs_source_get_type(child) == OBS_SOURCE_TYPE_TRANSITION &&
            !strcmp(obs_source_get_unversioned_id(child), "fade_transition")) *result = obs_source_get_ref(child);
    }, &result);
    return result;
}
static obs_source_t *copy_mix(Output *output, obs_source_t *source)
{
    auto *fade = active_fade(source);
    if (!fade) return nullptr;
    auto *a = obs_transition_get_source(fade, OBS_TRANSITION_SOURCE_A);
    auto *b = obs_transition_get_source(fade, OBS_TRANSITION_SOURCE_B);
    const float time = obs_transition_get_time(fade);
    auto *checkA = obs_transition_get_source(fade, OBS_TRANSITION_SOURCE_A);
    auto *checkB = obs_transition_get_source(fade, OBS_TRANSITION_SOURCE_B);
    const bool stable = a && b && a != b && a == checkA && b == checkB && time >= 0.0f && time < 1.0f;
    obs_source_release(checkA); obs_source_release(checkB);
    obs_source_t *copy = nullptr;
    if (stable) {
        auto *copyA = duplicate_camera(a);
        auto *copyB = duplicate_camera(b);
        if (copyA && copyB) {
            copy = obs_source_create_private("fade_transition", "Sunjoo OBS Link Frozen MIX", nullptr);
            if (copy) {
                uint32_t width, height; obs_transition_get_size(fade, &width, &height);
                obs_transition_set_size(copy, width, height);
                obs_transition_set_alignment(copy, obs_transition_get_alignment(fade));
                obs_transition_set_scale_type(copy, obs_transition_get_scale_type(fade));
                obs_transition_set(copy, copyA);
                if (obs_transition_start(copy, OBS_TRANSITION_MODE_MANUAL, output->duration, copyB)) {
                    obs_transition_set_manual_torque(copy, 0.0f, 0.0f);
                    // OBS treats exactly zero as a manual-transition cancel.
                    obs_transition_set_manual_time(copy, std::max(time, 0.000001f));
                    output->continuing = true; output->capturedTime = time; output->capturedAt = os_gettime_ns();
                } else { obs_source_release(copy); copy = nullptr; }
            }
        }
        obs_source_release(copyA); obs_source_release(copyB);
    }
    obs_source_release(a); obs_source_release(b); obs_source_release(fade);
    return copy;
}
static obs_source_t *acquire(Output *output)
{
    std::lock_guard<std::mutex> lock(output->mutex);
    return obs_source_get_ref(output->child);
}
static void replace(Output *output, obs_source_t *child)
{
    {
        std::lock_guard<std::mutex> lock(output->mutex);
        if (child == output->child) { obs_source_release(child); return; }
    }
    if (child && (child == output->self || !obs_source_add_active_child(output->self, child))) {
        obs_source_release(child);
        return;
    }
    obs_source_t *old;
    {
        std::lock_guard<std::mutex> lock(output->mutex);
        old = output->child;
        output->child = child;
    }
    if (old) {
        obs_source_remove_active_child(output->self, old);
        obs_source_release(old);
    }
}
static void update(void *opaque, obs_data_t *settings)
{
    auto *output = static_cast<Output *>(opaque);
    if (output->frozen) return;
    replace(output, obs_get_source_by_uuid(obs_data_get_string(settings, "live_uuid")));
}
static void *create(obs_data_t *settings, obs_source_t *source)
{
    auto *output = new Output{source, {}, nullptr, obs_obj_is_private(source)};
    const auto duration = obs_data_get_int(settings, "mix_duration_ms");
    output->duration = duration > 0 ? uint32_t(std::clamp<int64_t>(duration, 50, 5000)) : 300;
    auto *live = obs_get_source_by_uuid(obs_data_get_string(settings, "live_uuid"));
    if (output->frozen) {
        auto *target = obs_get_source_by_uuid(obs_data_get_string(settings, "frozen_uuid"));
        if (!target) target = obs_get_source_by_uuid(obs_data_get_string(settings, "snapshot_uuid"));
        if (target) {
            auto *copy = copy_mix(output, *obs_data_get_string(settings, "frozen_uuid") ? target : live);
            if (!copy) copy = duplicate_camera(target);
            if (copy) {
                obs_data_set_string(settings, "frozen_uuid", obs_source_get_uuid(copy));
            }
            // create runs under OBS's source registry lock. Initial activation
            // is propagated by enum_active_sources when the parent is shown.
            // Do not recursively enumerate a composite child under that lock.
            output->child = copy;
            obs_source_release(target);
        }
        obs_source_release(live);
    } else output->child = live;
    return output;
}
static void tick(void *opaque, float)
{
    auto *output = static_cast<Output *>(opaque);
    if (!output->continuing) return;
    auto *child = acquire(output);
    const float progress = std::min(1.0f, output->capturedTime +
        float(double(os_gettime_ns() - output->capturedAt) / (double(output->duration) * 1000000.0)));
    if (child) obs_transition_set_manual_time(child, progress);
    if (progress >= 1.0f) output->continuing = false;
    obs_source_release(child);
}
static void destroy(void *opaque)
{
    auto *output = static_cast<Output *>(opaque);
    replace(output, nullptr);
    delete output;
}
static void render(void *opaque, gs_effect_t *)
{
    auto *source = acquire(static_cast<Output *>(opaque));
    if (source) obs_source_video_render(source);
    obs_source_release(source);
}
static uint32_t dimension(void *opaque, bool height)
{
    auto *source = acquire(static_cast<Output *>(opaque));
    auto value = height ? obs_source_get_height(source) : obs_source_get_width(source);
    obs_source_release(source);
    return value;
}
static void enumerate(void *opaque, obs_source_enum_proc_t callback, void *param)
{
    auto *output = static_cast<Output *>(opaque);
    auto *child = acquire(output);
    if (child) callback(output->self, child, param);
    obs_source_release(child);
}
static bool audio(void *opaque, uint64_t *timestamp, obs_source_audio_mix *destination,
                  uint32_t mixers, size_t channels, size_t)
{
    auto *source = acquire(static_cast<Output *>(opaque));
    if (!source || obs_source_audio_pending(source)) { obs_source_release(source); return false; }
    *timestamp = obs_source_get_audio_timestamp(source);
    if (!*timestamp) { obs_source_release(source); return false; }
    obs_source_audio_mix input{};
    obs_source_get_audio_mix(source, &input);
    for (size_t mix = 0; mix < MAX_AUDIO_MIXES; ++mix)
        if (mixers & (1u << mix))
            for (size_t channel = 0; channel < channels && channel < MAX_AUDIO_CHANNELS; ++channel)
                if (destination->output[mix].data[channel] && input.output[mix].data[channel])
                    memcpy(destination->output[mix].data[channel], input.output[mix].data[channel], AUDIO_OUTPUT_FRAMES * sizeof(float));
    obs_source_release(source);
    return true;
}
static const char *name(void *) { return "Sunjoo OBS Link Controller " HYBRID_VERSION " / SunjooAn"; }
static obs_properties_t *properties(void *)
{
    auto *props = obs_properties_create();
    obs_properties_add_text(props, "credits", "Sunjoo OBS Link Controller " HYBRID_VERSION " / SunjooAn — Lua에서 설정합니다.", OBS_TEXT_INFO);
    return props;
}
MODULE_EXPORT bool obs_module_load(void)
{
    obs_source_info info{};
    info.id = "camera_mix_hybrid_output";
    info.type = OBS_SOURCE_TYPE_INPUT;
    info.output_flags = OBS_SOURCE_VIDEO | OBS_SOURCE_CUSTOM_DRAW | OBS_SOURCE_COMPOSITE;
    info.get_name = name; info.create = create; info.destroy = destroy; info.update = update;
    info.video_render = render; info.get_width = [](void *data) { return dimension(data, false); };
    info.get_height = [](void *data) { return dimension(data, true); };
    info.enum_active_sources = enumerate; info.enum_all_sources = enumerate;
    info.audio_render = audio; info.get_properties = properties;
    info.video_tick = tick;
    obs_register_source(&info);
    return true;
}
