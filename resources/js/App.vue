<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router';

import AppShell from '@/layouts/AppShell.vue';

const route = useRoute();
</script>

<template>
    <AppShell v-if="route.name !== 'landing'">
        <RouterView />
    </AppShell>

    <RouterView v-else />
</template>