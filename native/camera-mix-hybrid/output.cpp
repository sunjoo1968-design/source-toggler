// Sunjoo OBS Link Controller / SunjooAn. SPDX-License-Identifier: GPL-2.0-or-later
#include <obs-module.h>
#include <mutex>
#include <cstring>
#include <algorithm>

OBS_DECLARE_MODULE()
MODULE_EXPORT const char *obs_module_version(void) { return HYBRID_VERSION; }
MODULE_EXPORT const char *obs_module_name(void) { return "Sunjoo OBS Link Controller " HYBRID_VERSION; }
MODULE_EXPORT const char *obs_module_description(void) { return "Sunjoo OBS Link Controller clone-safe output / SunjooAn / " HYBRID_VERSION; }
MODULE_EXPORT const char *obs_module_author(void) { return "SunjooAn"; }

struct Output {
    obs_source_t *self;
    std::mutex mutex;
    obs_source_t *child = nullptr;
    bool frozen;
};
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
    auto *live = obs_get_source_by_uuid(obs_data_get_string(settings, "live_uuid"));
    if (output->frozen) {
        auto *target = obs_get_source_by_uuid(obs_data_get_string(settings, "frozen_uuid"));
        if (!target) target = obs_get_source_by_uuid(obs_data_get_string(settings, "snapshot_uuid"));
        if (target) {
            auto *copy = obs_source_duplicate(target, obs_source_get_name(target), true);
            if (copy) {
                obs_data_set_string(settings, "frozen_uuid", obs_source_get_uuid(copy));
                auto *meta = obs_source_get_private_settings(copy);
                auto *origin = obs_source_get_private_settings(target);
                const char *original = obs_data_get_string(origin, "camera_mix_hybrid_original_uuid");
                obs_data_set_string(meta, "camera_mix_hybrid_original_uuid", *original ? original : obs_source_get_uuid(target));
                obs_data_release(origin);
                obs_data_release(meta);
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
    obs_register_source(&info);
    return true;
}
