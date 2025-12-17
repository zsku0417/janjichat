<script setup>
import AuthenticatedLayout from "@/Layouts/AuthenticatedLayout.vue";
import Tab from "@/Components/Tab.vue";
import GeneralSettings from "@/Components/Settings/GeneralSettings.vue";
import RestaurantSettings from "@/Components/Settings/RestaurantSettings.vue";
import TablesSettings from "@/Components/Settings/TablesSettings.vue";
import OrderTrackingSettings from "@/Components/Settings/OrderTrackingSettings.vue";
import { Head } from "@inertiajs/vue3";
import { ref, computed } from "vue";

const props = defineProps({
    businessType: String,
    merchantSettings: Object,
    restaurantSettings: Object,
    orderTrackingSettings: Object,
    tables: Array,
});

// Active tab
const activeTab = ref("general");

// Business type checks
const isRestaurant = computed(() => props.businessType === "restaurant");
const isOrderTracking = computed(() => props.businessType === "order_tracking");

// Tab configuration
const tabs = computed(() => {
    const baseTabs = [{ key: "general", label: "General" }];

    if (isRestaurant.value) {
        baseTabs.push({ key: "restaurant", label: "Restaurant" });
        baseTabs.push({
            key: "tables",
            label: "Tables",
            badge: props.tables?.length || 0,
        });
    }

    if (isOrderTracking.value) {
        baseTabs.push({ key: "order-tracking", label: "Order Tracking" });
    }

    return baseTabs;
});
</script>

<template>
    <Head title="Settings" />

    <AuthenticatedLayout>
        <template #header>
            <div>
                <h2 class="text-2xl font-bold text-gradient">Settings</h2>
                <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                    Manage your business settings and preferences
                </p>
            </div>
        </template>

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <div
                    class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700"
                >
                    <!-- Tabs -->
                    <div class="px-6 pt-6">
                        <Tab v-model="activeTab" :tabs="tabs" />
                    </div>

                    <!-- Tab Content -->
                    <div class="p-6">
                        <!-- General Settings Tab -->
                        <div v-if="activeTab === 'general'">
                            <GeneralSettings
                                :settings="merchantSettings"
                                :business-type="businessType"
                            />
                        </div>

                        <!-- Restaurant Settings Tab -->
                        <div v-if="activeTab === 'restaurant' && isRestaurant">
                            <RestaurantSettings
                                :settings="restaurantSettings"
                            />
                        </div>

                        <!-- Tables Tab (Restaurant only) -->
                        <div v-if="activeTab === 'tables' && isRestaurant">
                            <TablesSettings :tables="tables" />
                        </div>

                        <!-- Order Tracking Settings Tab -->
                        <div
                            v-if="
                                activeTab === 'order-tracking' &&
                                isOrderTracking
                            "
                        >
                            <OrderTrackingSettings
                                :settings="orderTrackingSettings"
                            />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>

<style scoped>
.text-gradient {
    @apply bg-gradient-to-r from-primary-500 to-secondary-500 bg-clip-text text-transparent;
}
</style>
