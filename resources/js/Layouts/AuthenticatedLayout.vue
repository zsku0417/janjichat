<script setup>
import { ref, computed, watch } from "vue";
import Dropdown from "@/Components/Dropdown.vue";
import DropdownLink from "@/Components/DropdownLink.vue";
import ThemeToggle from "@/Components/ThemeToggle.vue";
import Alert from "@/Components/Alert.vue";
import { Link, usePage } from "@inertiajs/vue3";

const showingNavigationDropdown = ref(false);
const isCollapsed = ref(false);
const isHovered = ref(false);

// Computed property to determine if sidebar should show expanded state
const isExpanded = computed(() => !isCollapsed.value || isHovered.value);

const toggleSidebar = () => {
    isCollapsed.value = !isCollapsed.value;
    // Reset hover state when manually toggling
    if (!isCollapsed.value) {
        isHovered.value = false;
    }
};

const handleMouseEnter = () => {
    if (isCollapsed.value) {
        isHovered.value = true;
    }
};

const handleMouseLeave = () => {
    if (isCollapsed.value) {
        isHovered.value = false;
    }
};

const page = usePage();
const user = computed(() => page.props.auth.user);
const businessType = computed(() => user.value?.business_type || "restaurant");
const isAdmin = computed(() => user.value?.role === "admin");

// Alert state management
const showAlert = ref(false);
const alertType = ref("info");
const alertMessage = ref("");

// Watch for flash messages from server
watch(
    () => page.props.flash,
    (flash) => {
        if (flash?.success) {
            alertType.value = "success";
            alertMessage.value = flash.success;
            showAlert.value = true;
        } else if (flash?.error) {
            alertType.value = "error";
            alertMessage.value = flash.error;
            showAlert.value = true;
        } else if (flash?.warning) {
            alertType.value = "warning";
            alertMessage.value = flash.warning;
            showAlert.value = true;
        } else if (flash?.info) {
            alertType.value = "info";
            alertMessage.value = flash.info;
            showAlert.value = true;
        }
    },
    { immediate: true }
);

const handleAlertDismiss = () => {
    showAlert.value = false;
};

// Navigation items based on business type and role
const navigationItems = computed(() => {
    // Admin sees admin-only navigation
    if (isAdmin.value) {
        return [
            { name: "Dashboard", route: "dashboard", icon: "home" },
            {
                name: "Merchants",
                route: "admin.merchants.index",
                pattern: "admin.merchants.*",
                icon: "users",
            },
            {
                name: "Knowledge Base",
                route: "documents.index",
                pattern: "documents.*",
                icon: "book",
            },
        ];
    }

    // Merchant navigation
    const shared = [
        { name: "Dashboard", route: "dashboard", icon: "home" },
        {
            name: "Conversations",
            route: "conversations.index",
            pattern: "conversations.*",
            icon: "chat",
        },
        {
            name: "Knowledge Base",
            route: "documents.index",
            pattern: "documents.*",
            icon: "book",
        },
    ];

    if (businessType.value === "restaurant") {
        return [
            ...shared,
            {
                name: "Bookings",
                route: "bookings.index",
                pattern: "bookings.*",
                icon: "calendar",
            },
            {
                name: "Settings",
                route: "settings.index",
                pattern: "settings.*",
                icon: "settings",
            },
        ];
    }

    // order_tracking
    return [
        ...shared,
        {
            name: "Products",
            route: "products.index",
            pattern: "products.*",
            icon: "package",
        },
        {
            name: "Orders",
            route: "orders.index",
            pattern: "orders.*",
            icon: "orders",
        },
        {
            name: "Settings",
            route: "settings.index",
            pattern: "settings.*",
            icon: "settings",
        },
        {
            name: "My Shop",
            href: user.value?.id ? `/shop/${user.value.id}` : "#",
            icon: "storefront",
            external: true,
        },
    ];
});

const isActive = (item) => {
    // External links are never "active" in the same way
    if (item.external || !item.route) {
        return false;
    }
    if (item.pattern) {
        return route().current(item.pattern);
    }
    return route().current(item.route);
};

const getIcon = (iconName) => {
    const icons = {
        home: "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6",
        chat: "M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z",
        book: "M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253",
        calendar:
            "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z",
        settings:
            "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z",
        package:
            "M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4",
        orders: "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01",
        users: "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z",
        storefront:
            "M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z",
    };
    return icons[iconName] || icons.home;
};
</script>

<template>
    <div
        class="min-h-screen bg-gradient-to-br from-slate-50 via-purple-50 to-cyan-50 dark:from-slate-900 dark:via-purple-900/20 dark:to-cyan-900/20 dark:text-slate-200 transition-colors duration-300"
    >
        <!-- Desktop Sidebar -->
        <aside
            @mouseenter="handleMouseEnter"
            @mouseleave="handleMouseLeave"
            :class="[
                'hidden lg:flex flex-col fixed left-0 top-0 h-screen z-50 glass border-r border-white/20 dark:border-white/10 transition-all duration-300 ease-in-out',
                isExpanded ? 'w-64' : 'w-20',
            ]"
        >
            <!-- Logo Section -->
            <div
                class="flex items-center h-16 px-4 border-b border-white/20 dark:border-white/10"
            >
                <Link
                    :href="route('dashboard')"
                    class="flex items-center gap-3 overflow-hidden"
                >
                    <img
                        src="/images/Logo-Icon.png"
                        alt="Janji Chat Logo"
                        class="w-10 h-10 min-w-[2.5rem] rounded-xl shadow-lg shadow-primary-500/30 object-contain"
                    />
                    <span
                        :class="[
                            'text-xl font-bold text-gradient whitespace-nowrap transition-all duration-300',
                            isExpanded
                                ? 'opacity-100 translate-x-0'
                                : 'opacity-0 -translate-x-4',
                        ]"
                        >Janji Chat</span
                    >
                </Link>
            </div>

            <!-- Navigation Links -->
            <nav
                class="flex-1 px-3 py-4 space-y-1 overflow-y-auto overflow-x-hidden"
            >
                <template
                    v-for="item in navigationItems"
                    :key="item.route || item.name"
                >
                    <!-- External Link -->
                    <a
                        v-if="item.external"
                        :href="item.href"
                        target="_blank"
                        :class="[
                            'group flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200',
                            'text-cyan-600 dark:text-cyan-400 hover:text-cyan-700 dark:hover:text-cyan-300 hover:bg-cyan-50 dark:hover:bg-cyan-900/20',
                        ]"
                        :title="!isExpanded ? item.name : undefined"
                    >
                        <svg
                            class="w-5 h-5 min-w-[1.25rem]"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                :d="getIcon(item.icon)"
                            />
                        </svg>
                        <span
                            :class="[
                                'whitespace-nowrap transition-all duration-300 flex items-center gap-1',
                                isExpanded
                                    ? 'opacity-100 translate-x-0'
                                    : 'opacity-0 -translate-x-4 absolute',
                            ]"
                        >
                            {{ item.name }}
                            <svg
                                class="w-3 h-3"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                                />
                            </svg>
                        </span>
                    </a>
                    <!-- Internal Link -->
                    <Link
                        v-else
                        :href="route(item.route)"
                        :class="[
                            'group flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200',
                            isActive(item)
                                ? 'bg-gradient-to-r from-primary-500 to-primary-600 text-white shadow-lg shadow-primary-500/30'
                                : 'text-gray-600 dark:text-gray-300 hover:text-primary-600 dark:hover:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/20',
                        ]"
                        :title="!isExpanded ? item.name : undefined"
                    >
                        <svg
                            class="w-5 h-5 min-w-[1.25rem]"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                :d="getIcon(item.icon)"
                            />
                        </svg>
                        <span
                            :class="[
                                'whitespace-nowrap transition-all duration-300',
                                isExpanded
                                    ? 'opacity-100 translate-x-0'
                                    : 'opacity-0 -translate-x-4 absolute',
                            ]"
                            >{{ item.name }}</span
                        >
                    </Link>
                </template>

                <!-- Simulator (Dev only) -->
                <Link
                    :href="route('dev.simulator')"
                    :class="[
                        'group flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200',
                        route().current('dev.*')
                            ? 'bg-gradient-to-r from-amber-500 to-orange-500 text-white shadow-lg shadow-orange-500/30'
                            : 'text-amber-600 dark:text-amber-400 hover:text-amber-700 dark:hover:text-amber-300 hover:bg-amber-50 dark:hover:bg-amber-900/20',
                    ]"
                    :title="!isExpanded ? 'Simulator' : undefined"
                >
                    <span class="text-lg min-w-[1.25rem] flex justify-center"
                        >🧪</span
                    >
                    <span
                        :class="[
                            'whitespace-nowrap transition-all duration-300',
                            isExpanded
                                ? 'opacity-100 translate-x-0'
                                : 'opacity-0 -translate-x-4 absolute',
                        ]"
                        >Simulator</span
                    >
                </Link>
            </nav>

            <!-- Bottom Section -->
            <div
                class="border-t border-white/20 dark:border-white/10 p-3 space-y-2 overflow-visible"
            >
                <!-- Theme Toggle -->
                <div
                    :class="[
                        'flex items-center gap-3 px-3 py-2',
                        isExpanded ? 'justify-between' : 'justify-center',
                    ]"
                >
                    <span
                        v-if="isExpanded"
                        class="text-sm font-medium text-gray-600 dark:text-gray-300 whitespace-nowrap"
                        >Theme</span
                    >
                    <ThemeToggle />
                </div>

                <!-- Role/Business Type Badge -->
                <div
                    v-if="isExpanded"
                    :class="[
                        'flex items-center justify-center px-3 py-2 rounded-xl text-xs font-medium transition-all duration-300',
                        isAdmin
                            ? 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300'
                            : businessType === 'restaurant'
                            ? 'bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-300'
                            : 'bg-cyan-100 dark:bg-cyan-900/30 text-cyan-700 dark:text-cyan-300',
                    ]"
                >
                    {{
                        isAdmin
                            ? "👑 Admin"
                            : businessType === "restaurant"
                            ? "🍽️ Restaurant"
                            : "📦 Order Tracking"
                    }}
                </div>

                <!-- User Profile -->
                <Dropdown align="right" width="48" direction="up">
                    <template #trigger>
                        <button
                            type="button"
                            :class="[
                                'w-full flex items-center gap-3 px-3 py-2 rounded-xl bg-white/50 dark:bg-slate-800/50 border border-white/20 dark:border-white/10 text-sm font-medium text-gray-700 dark:text-gray-200 transition-all hover:bg-white/80 dark:hover:bg-slate-700/50 hover:shadow-lg',
                                isExpanded ? 'justify-start' : 'justify-center',
                            ]"
                        >
                            <div
                                class="w-8 h-8 min-w-[2rem] bg-gradient-to-br from-primary-400 to-secondary-400 rounded-lg flex items-center justify-center text-white font-semibold"
                            >
                                {{
                                    user?.name?.charAt(0)?.toUpperCase() || "?"
                                }}
                            </div>
                            <span
                                v-if="isExpanded"
                                class="flex-1 text-left truncate"
                                >{{ user?.name || "User" }}</span
                            >
                            <svg
                                v-if="isExpanded"
                                class="h-4 w-4"
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 20 20"
                                fill="currentColor"
                            >
                                <path
                                    fill-rule="evenodd"
                                    d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                                    clip-rule="evenodd"
                                />
                            </svg>
                        </button>
                    </template>

                    <template #content>
                        <DropdownLink
                            :href="route('logout')"
                            method="post"
                            as="button"
                        >
                            Log Out
                        </DropdownLink>
                        <DropdownLink :href="route('profile.edit')">
                            Profile
                        </DropdownLink>
                    </template>
                </Dropdown>

                <!-- Collapse Toggle Button -->
                <button
                    @click="toggleSidebar"
                    :class="[
                        'w-full flex items-center gap-3 px-3 py-2 rounded-xl text-sm font-medium text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-slate-700/50 transition-all duration-200',
                        isExpanded ? 'justify-start' : 'justify-center',
                    ]"
                    :title="isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'"
                >
                    <svg
                        :class="[
                            'w-5 h-5 transition-transform duration-300',
                            isCollapsed ? 'rotate-180' : '',
                        ]"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M11 19l-7-7 7-7m8 14l-7-7 7-7"
                        />
                    </svg>
                    <span v-if="isExpanded" class="whitespace-nowrap"
                        >Collapse</span
                    >
                </button>
            </div>
        </aside>

        <!-- Mobile Header -->
        <nav
            class="lg:hidden glass sticky top-0 z-50 border-b border-white/20 dark:border-white/10"
        >
            <div class="px-4">
                <div class="flex h-16 justify-between">
                    <div class="flex items-center">
                        <Link
                            :href="route('dashboard')"
                            class="flex items-center space-x-2"
                        >
                            <img
                                src="/images/Logo-Icon.png"
                                alt="Janji Chat Logo"
                                class="w-10 h-10 rounded-xl shadow-lg shadow-primary-500/30 object-contain"
                            />
                            <span class="text-xl font-bold text-gradient"
                                >Janji Chat</span
                            >
                        </Link>
                    </div>

                    <div class="flex items-center gap-2">
                        <ThemeToggle />
                        <button
                            @click="
                                showingNavigationDropdown =
                                    !showingNavigationDropdown
                            "
                            class="inline-flex items-center justify-center rounded-xl p-2 text-gray-500 dark:text-gray-400 transition-all hover:bg-white/50 dark:hover:bg-slate-700/50 hover:text-primary-600"
                        >
                            <svg
                                class="h-6 w-6"
                                stroke="currentColor"
                                fill="none"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    :class="{
                                        hidden: showingNavigationDropdown,
                                        'inline-flex':
                                            !showingNavigationDropdown,
                                    }"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M4 6h16M4 12h16M4 18h16"
                                />
                                <path
                                    :class="{
                                        hidden: !showingNavigationDropdown,
                                        'inline-flex':
                                            showingNavigationDropdown,
                                    }"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                        </button>
                    </div>
                </div>
            </div>

            <!-- Mobile Navigation Menu -->
            <div
                :class="{
                    block: showingNavigationDropdown,
                    hidden: !showingNavigationDropdown,
                }"
                class="bg-white/90 dark:bg-slate-800/90 backdrop-blur-lg border-t border-white/20 dark:border-white/10"
            >
                <div class="space-y-1 pb-3 pt-2 px-4">
                    <template
                        v-for="item in navigationItems"
                        :key="item.route || item.name"
                    >
                        <!-- External Link -->
                        <a
                            v-if="item.external"
                            :href="item.href"
                            target="_blank"
                            class="block px-4 py-2 rounded-lg text-sm font-medium text-cyan-600 dark:text-cyan-400 hover:bg-cyan-50 dark:hover:bg-cyan-900/20"
                        >
                            {{ item.name }}
                            <svg
                                class="inline w-3 h-3 ml-1"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                                />
                            </svg>
                        </a>
                        <!-- Internal Link -->
                        <Link
                            v-else
                            :href="route(item.route)"
                            :class="[
                                'block px-4 py-2 rounded-lg text-sm font-medium transition-all',
                                isActive(item)
                                    ? 'bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300'
                                    : 'text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700/50',
                            ]"
                        >
                            {{ item.name }}
                        </Link>
                    </template>
                    <Link
                        :href="route('dev.simulator')"
                        class="block px-4 py-2 rounded-lg text-sm font-medium text-amber-600 dark:text-amber-400 hover:bg-amber-50 dark:hover:bg-amber-900/20"
                    >
                        🧪 Simulator
                    </Link>
                </div>

                <!-- Mobile User Info -->
                <div
                    class="border-t border-gray-200 dark:border-gray-700 pb-1 pt-4 px-4"
                >
                    <div class="flex items-center gap-3 px-4 mb-3">
                        <div
                            class="w-10 h-10 bg-gradient-to-br from-primary-400 to-secondary-400 rounded-lg flex items-center justify-center text-white font-semibold"
                        >
                            {{ user?.name?.charAt(0)?.toUpperCase() || "?" }}
                        </div>
                        <div>
                            <div
                                class="text-base font-medium text-gray-800 dark:text-gray-200"
                            >
                                {{ user?.name || "User" }}
                            </div>
                            <div
                                class="text-sm font-medium text-gray-500 dark:text-gray-400"
                            >
                                {{ user?.email || "" }}
                            </div>
                        </div>
                    </div>

                    <div class="mt-3 space-y-1">
                        <Link
                            :href="route('profile.edit')"
                            class="block px-4 py-2 rounded-lg text-sm text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700/50"
                        >
                            Profile
                        </Link>
                        <Link
                            :href="route('logout')"
                            method="post"
                            as="button"
                            class="block w-full text-left px-4 py-2 rounded-lg text-sm text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700/50"
                        >
                            Log Out
                        </Link>
                    </div>
                </div>
            </div>
        </nav>

        <!-- Main Content Area -->
        <div
            :class="[
                'transition-all duration-300 ease-in-out',
                'lg:ml-20',
                isExpanded ? 'lg:ml-64' : 'lg:ml-20',
            ]"
        >
            <!-- Page Heading -->
            <header
                v-if="$slots.header"
                class="glass border-b border-white/20 dark:border-white/10"
            >
                <div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
                    <slot name="header" />
                </div>
            </header>

            <!-- Alert Messages -->
            <div
                v-if="showAlert"
                class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 mt-4"
            >
                <Alert
                    :type="alertType"
                    :message="alertMessage"
                    @dismiss="handleAlertDismiss"
                />
            </div>

            <!-- Page Content -->
            <main>
                <slot />
            </main>
        </div>
    </div>
</template>
