#include <pipewire/pipewire.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TRACKED_STREAMS 32

struct app_state {
  struct pw_main_loop *loop;
  struct pw_context *context;
  struct pw_core *core;
  struct pw_registry *registry;
  struct spa_hook registry_listener;

  uint32_t tracked_ids[MAX_TRACKED_STREAMS];
  size_t tracked_count;
};

// Check if a PipeWire Node ID is in our tracked list
static bool is_tracked(struct app_state *state, uint32_t id) {
  for (size_t i = 0; i < state->tracked_count; i++) {
    if (state->tracked_ids[i] == id)
      return true;
  }
  return false;
}

// Add a new screen share Node ID to our list
static void add_tracked(struct app_state *state, uint32_t id) {
  if (state->tracked_count < MAX_TRACKED_STREAMS && !is_tracked(state, id)) {
    state->tracked_ids[state->tracked_count++] = id;
  }
}

// Remove a Node ID from our tracked list if it exists
static bool remove_tracked(struct app_state *state, uint32_t id) {
  for (size_t i = 0; i < state->tracked_count; i++) {
    if (state->tracked_ids[i] == id) {
      // Swap removed element with the last element for fast O(1) removal
      state->tracked_ids[i] = state->tracked_ids[state->tracked_count - 1];
      state->tracked_count--;
      return true;
    }
  }
  return false;
}

// Output state status
static void update_state(struct app_state *state) {
  if (state->tracked_count > 0) {
    printf("[STATE] Screen Sharing: ACTIVE (%zu stream%s)\n",
           state->tracked_count, state->tracked_count == 1 ? "" : "s");
  } else {
    printf("[STATE] Screen Sharing: INACTIVE\n");
  }
  fflush(stdout);
}

static void registry_event_global(void *data, uint32_t id, uint32_t permissions,
                                  const char *type, uint32_t version,
                                  const struct spa_dict *props) {
  struct app_state *state = data;

  if (strcmp(type, PW_TYPE_INTERFACE_Node) == 0 && props != NULL) {
    const char *media_class = spa_dict_lookup(props, PW_KEY_MEDIA_CLASS);

    if (media_class && strcmp(media_class, "Stream/Input/Video") == 0) {
      add_tracked(state, id);
      update_state(state);
    }
  }
}

static void registry_event_global_remove(void *data, uint32_t id) {
  struct app_state *state = data;

  // Only react and print if the removed ID was actually one of our tracked
  // video streams!
  if (remove_tracked(state, id)) {
    update_state(state);
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
  pw_registry_add_listener(state.registry, &state.registry_listener,
                           &registry_events, &state);

  printf("Listening for screen share streams...\n");

  pw_main_loop_run(state.loop);

  pw_proxy_destroy((struct pw_proxy *)state.registry);
  pw_core_disconnect(state.core);
  pw_context_destroy(state.context);
  pw_main_loop_destroy(state.loop);

  return EXIT_SUCCESS;
}
