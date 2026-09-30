#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <pipewire/pipewire.h>

#define MAX_TRACKED_STREAMS 32

struct stream_info {
    uint32_t id;
    char app_name[128];
};

struct app_state {
    struct pw_main_loop *loop;
    struct pw_context *context;
    struct pw_core *core;
    struct pw_registry *registry;
    struct spa_hook registry_listener;

    struct stream_info streams[MAX_TRACKED_STREAMS];
    size_t stream_count;
};

// Formats active stream array into a clean JSON string
static void print_json_state(struct app_state *state) {
    printf("[");
    for (size_t i = 0; i < state->stream_count; i++) {
        printf("{\"id\":%u,\"app_name\":\"%s\"}%s",
               state->streams[i].id,
               state->streams[i].app_name,
               (i < state->stream_count - 1) ? "," : "");
    }
    printf("]\n");
    fflush(stdout);
}

// Store new stream with its PipeWire ID and Application Name
static void add_stream(struct app_state *state, uint32_t id, const char *app_name) {
    if (state->stream_count < MAX_TRACKED_STREAMS) {
        state->streams[state->stream_count].id = id;
        snprintf(state->streams[state->stream_count].app_name,
                 sizeof(state->streams[state->stream_count].app_name),
                 "%s", app_name ? app_name : "Unknown");
        state->stream_count++;
    }
}

// Remove stream by ID on stream destruction
static bool remove_stream(struct app_state *state, uint32_t id) {
    for (size_t i = 0; i < state->stream_count; i++) {
        if (state->streams[i].id == id) {
            // Swap with last item for O(1) removal
            state->streams[i] = state->streams[state->stream_count - 1];
            state->stream_count--;
            return true;
        }
    }
    return false;
}

static void registry_event_global(void *data, uint32_t id, uint32_t permissions,
                                  const char *type, uint32_t version,
                                  const struct spa_dict *props) {
    struct app_state *state = data;

    if (strcmp(type, PW_TYPE_INTERFACE_Node) == 0 && props != NULL) {
        const char *media_class = spa_dict_lookup(props, PW_KEY_MEDIA_CLASS);

        if (media_class && strcmp(media_class, "Stream/Input/Video") == 0) {
            // Extract application name property set by client/portal
            const char *app_name = spa_dict_lookup(props, PW_KEY_APP_NAME);

            // Fallback to node name if application name is missing
            if (!app_name) {
                app_name = spa_dict_lookup(props, PW_KEY_NODE_NAME);
            }

            add_stream(state, id, app_name);
            print_json_state(state);
        }
    }
}

static void registry_event_global_remove(void *data, uint32_t id) {
    struct app_state *state = data;

    if (remove_stream(state, id)) {
        print_json_state(state);
    }
}

static const struct pw_registry_events registry_events = {
    PW_VERSION_REGISTRY_EVENTS,
    .global = registry_event_global,
    .global_remove = registry_event_global_remove,
};

int main(int argc, char *argv[]) {
    pw_init(&argc, &argv);

    struct app_state state = {0};

    state.loop = pw_main_loop_new(NULL);
    state.context = pw_context_new(pw_main_loop_get_loop(state.loop), NULL, 0);
    state.core = pw_context_connect(state.context, NULL, 0);

    if (!state.core) {
        fprintf(stderr, "Failed to connect to PipeWire daemon.\n");
        return EXIT_FAILURE;
    }

    state.registry = pw_core_get_registry(state.core, PW_VERSION_REGISTRY, 0);
    pw_registry_add_listener(state.registry, &state.registry_listener, &registry_events, &state);

    // Print initial empty JSON array state
    print_json_state(&state);

    pw_main_loop_run(state.loop);

    pw_proxy_destroy((struct pw_proxy *)state.registry);
    pw_core_disconnect(state.core);
    pw_context_destroy(state.context);
    pw_main_loop_destroy(state.loop);

    return EXIT_SUCCESS;
}
