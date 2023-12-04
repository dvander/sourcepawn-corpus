#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vsh2>
#include <morecolors>
#include <tf2attributes>
#include <tf2items>
#include <tf2_stocks>
#include <dhooks>

#define PLUGIN_TITLE     "Cleaner's Carbine Rocket"
#define PLUGIN_AUTHOR    "Your Name"
#define PLUGIN_DESC      "Launch a rocket when using Cleaner's Carbine with right-click."
#define PLUGIN_VERSION   "1.0"

public Action OnPlayerRunCmd(int client, int buttons, int impulse, float view, int num_buttons)
{
    if (buttons & IN_ATTACK2) // Check if right-click is pressed
    {
        if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Sniper)
        {
            int cleanerCarbineIndex = GetItemIndex("tf_weapon_charged_smg");
            if (cleanerCarbineIndex != -1)
            {
                int ammoCount = GetEntProp(client, Prop_Send, "m_iAmmo.001"); // Check Cleaner's Carbine ammo count
                if (ammoCount >= 25) // Adjust this value as needed
                {
                    LaunchRocket(client); // Launch the rocket
                    SetEntProp(client, Prop_Send, "m_iAmmo.001", ammoCount - 25); // Deduct ammo
                }
            }
        }
    }
    return Plugin_Handled;
}

public Action LaunchRocket(int client)
{
    new Float:angles[3];
    GetClientEyeAngles(client, angles);

    new Float:forward[3];
    AngleVectors(angles, forward);

    new Float:origin[3];
    GetClientOrigin(client, origin);

    new rocket = CreateEntityByName("tf_projectile_rocket");
    if (!IsValidEntity(rocket))
        return;

    DispatchKeyValue(rocket, "tf_projectile_rocket_type", "1"); // Set rocket type to standard

    VectorScale(forward, 1000.0, forward); // Adjust speed as needed
    SetEntPropVector(rocket, Prop_Send, "m_vecVelocity", forward);
    SetEntPropVector(rocket, Prop_Send, "m_vecOrigin", origin);

    DispatchSpawn(rocket);
    DispatchThink(rocket);

    SetEntityOwner(rocket, client);

    RemoveEntity(rocket, 5.0); // Remove the rocket after 5 seconds
}
