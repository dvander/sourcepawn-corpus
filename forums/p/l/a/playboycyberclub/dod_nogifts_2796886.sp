#include <sdktools>
#include <sdkhooks>

#define PLUGIN_NAME    "DOD:S No Gifts"
#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{ 
        name = PLUGIN_NAME, 
        author = "Root, playboycyberclub", 
        description = "Get rid of annoying gifts on a servers without mp_holiday_nogifts cvar!", 
        version = PLUGIN_VERSION, 
        url = "http://dodsplugins.com/"};

public OnPluginStart()
{ 
        CreateConVar("dod_nogifts_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_REPLICATED); AddNormalSoundHook(NormalSHook:HookGiftSound); 
}
        public OnEntityCreated(entity, const String:classname[])
{ 
        if (IsValidEdict(entity))if (StrEqual(classname, "holiday_gift"))AcceptEntityInput(entity, "KillHierarchy"); 
}
        public Action:HookGiftSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{ 
        return (StrEqual(sample, "UI/gift_drop.wav") || StrEqual(sample, "items/gift_drop.wav")) ? Plugin_Stop : Plugin_Continue; 
} 