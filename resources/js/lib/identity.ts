import { getVisitorId } from '@/lib/visitor';
import { useAuth } from '@/composables/useAuth';

export function getIdentityHeaders(): HeadersInit {
    const { isAuthenticated } = useAuth();

    if (isAuthenticated.value) {
        return {};
    }

    const visitorId = getVisitorId();

    if (!visitorId) {
        throw new Error(
            'Unable to identify this browser.',
        );
    }

    return {
        'X-Visitor-Id': visitorId,
    };
}
