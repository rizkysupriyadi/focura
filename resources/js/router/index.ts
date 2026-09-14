import {
    createRouter,
    createWebHistory,
} from 'vue-router';

import {
    useAuth,
} from '@/composables/useAuth';

import Focus from '@/pages/Focus.vue';
import ForgotPassword from '@/pages/ForgotPassword.vue';
import Insights from '@/pages/Insights.vue';
import Landing from '@/pages/Landing.vue';
import Login from '@/pages/Login.vue';
import Register from '@/pages/Register.vue';
import ResetPassword from '@/pages/ResetPassword.vue';
import SessionDetail from '@/pages/SessionDetail.vue';
import Sessions from '@/pages/Sessions.vue';
import Settings from '@/pages/Settings.vue';

const router = createRouter({
    history: createWebHistory(),

    routes: [
        {
            path: '/',
            name: 'landing',
            component: Landing,
        },
        {
            path: '/login',
            name: 'login',
            component: Login,
            meta: {
                guestOnly: true,
            },
        },

        {
            path: '/forgot-password',
            name: 'forgot-password',
            component: ForgotPassword,
            meta: {
                guestOnly: true,
            },
        },
        {
            path: '/reset-password',
            name: 'reset-password',
            component: ResetPassword,
        },

        {
            path: '/register',
            name: 'register',
            component: Register,
            meta: {
                guestOnly: true,
            },
        },
        {
            path: '/focus',
            name: 'focus',
            component: Focus,
        },
        {
            path: '/sessions',
            name: 'sessions',
            component: Sessions,
        },
        {
            path: '/sessions/:id',
            name: 'session-detail',
            component: SessionDetail,
        },
        {
            path: '/insights',
            name: 'insights',
            component: Insights,
        },
        {
            path: '/settings',
            name: 'settings',
            component: Settings,
        },
    ],

    scrollBehavior: () => ({
        top: 0,
    }),
});

router.beforeEach(async (to) => {
    const {
        isAuthenticated,
        initializeAuth,
    } = useAuth();

    await initializeAuth();

    if (
        to.meta.guestOnly === true &&
        isAuthenticated.value
    ) {
        return {
            name: 'focus',
        };
    }

    return true;
});

export default router;
