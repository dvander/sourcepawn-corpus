#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

char g_sGrenadeProjectiles[][] =
{
	"hegrenade_projectile",
	"flashbang_projectile",
	"smokegrenade_projectile",
	"decoy_projectile",
	"molotov_projectile",
	"incgrenade_projectile"
};

int g_iSize;

public Plugin myinfo =
{
    name        = "Impact Grenade",
    author      = "Cruze, Code Taken from Grenade Modes of Nyuu",
    description = "Impact grenades for everyone",
    version     = "1.0.0",
    url         = "https://forums.alliedmods.net/showthread.php?t=342051"
}

public void OnPluginStart()
{
	g_iSize = sizeof(g_sGrenadeProjectiles);
}

public void OnEntityCreated(int iEntity, const char[] szClassname)
{
	for(int i = 0; i < g_iSize; i++) if(!strcmp(szClassname, g_sGrenadeProjectiles[i]))
	{
		SDKHook(iEntity, SDKHook_SpawnPost, OnGrenadeSpawnPost);
		break;
	}
}

public void OnGrenadeSpawnPost(int iGrenade)
{
	CreateTimer(0.1, OnGrenadeTimerSetInfinite, EntIndexToEntRef(iGrenade), TIMER_FLAG_NO_MAPCHANGE);
	SDKHook(iGrenade, SDKHook_TouchPost, OnGrenadeImpactTouchPost);
}

public void OnGrenadeImpactTouchPost(int iGrenade, int iOther)
{
	// Check if the grenade touches the world
	if (!iOther)
	{
		// Detonate the grenade
		GrenadeDetonate(iGrenade);
	}
	else
	{
		// Check if the grenade touches a solid entity
		if (GetEntProp(iOther, Prop_Send, "m_nSolidType", 1) && !(GetEntProp(iOther, Prop_Send, "m_usSolidFlags", 2) & 0x0004))
		{
			// Get the grenade owner
			int iOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");

			// Check if it's not the owner
			if (iOwner != iOther)
			{
				// Detonate the grenade
				GrenadeDetonate(iGrenade);
			}
		}
	}
}

public Action OnGrenadeTimerSetInfinite(Handle hTimer, int iReference)
{
	// Get the grenade index
	int iGrenade = EntRefToEntIndex(iReference);

	// Check if the grenade is still valid
	if (iGrenade != INVALID_ENT_REFERENCE)
	{
		// Set the grenade as infinite
		SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", -1);
	}

	return Plugin_Continue;
}

static void GrenadeDetonate(int iGrenade)
{
    char szClassname[32];
    
    // Get the grenade classname
    GetEdictClassname(iGrenade, szClassname, sizeof(szClassname));
    
    // Check if the grenade is a smoke
    if (StrEqual(szClassname, "smokegrenade_projectile"))
    {
        float vGrenadeVelocity[3] = {0.0, 0.0, 0.0};
        
        // Stop the grenade velocity
        TeleportEntity(iGrenade, NULL_VECTOR, NULL_VECTOR, vGrenadeVelocity);
        
        // Explode in the next tick
        SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", 1);
    }
    else
    {
        // Set the grenade as breakable
        GrenadeSetBreakable(iGrenade);
        
        // Inflict damage
        SDKHooks_TakeDamage(iGrenade, iGrenade, iGrenade, 10.0);
    }
}

static void GrenadeSetBreakable(int iGrenade)
{
    // Set the grenade as breakable
    SetEntProp(iGrenade, Prop_Data, "m_takedamage", 2);
    SetEntProp(iGrenade, Prop_Data, "m_iHealth", 1);
}