import { createApp } from 'vue';

import App from '@/App.vue';
import router from '@/router';

import '../css/app.css';

const app = createApp(App);

app.use(router);

app.mount('#app');

if (
    import.meta.env.PROD &&
    'serviceWorker' in navigator
) {
    window.addEventListener('load', () => {
        void navigator.serviceWorker.register(
            '/sw.js',
            {
                scope: '/',
            },
        );
    });
}
