//by sidezz
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Frag Sprite/Trail Fix",
	author = "sidezz",
	description = "Fixes the duplicating env_sprite and env_spritetrail on npc_grenade_frag",
	version = "69",
	url = "https://www.coldcommunity.com"
};

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "env_sprite", false) || StrEqual(classname, "env_spritetrail", false)) RequestFrame(GetSpriteData, EntIndexToEntRef(entity));
}

void GetSpriteData(int ref)
{
	int sprite = EntRefToEntIndex(ref);
	if(IsValidEntity(sprite))
	{
		//Check what we're attached to:
		int nade = GetEntPropEnt(sprite, Prop_Data, "m_hAttachedToEntity");

		//If no nade was found, or ent is not attached to anything:
		if(nade == -1) return;

		char class[32];
		GetEdictClassname(nade, class, sizeof(class));

		//If it's even worth pursuing more data:
		if(StrEqual(class, "npc_grenade_frag", false))
		{
			//Start at maxclients:
			for(int i = MaxClients + 1; i < 2048; i++)
			{
				if(!IsValidEntity(i)) continue;

				char otherClass[32]; 
				GetEdictClassname(i, otherClass, sizeof(otherClass))

				if(StrEqual(otherClass, "env_spritetrail", false) || StrEqual(otherClass, "env_sprite", false))
				{
					if(GetEntPropEnt(i, Prop_Data, "m_hAttachedToEntity") == nade)
					{
						int glow = GetEntPropEnt(nade, Prop_Data, "m_pMainGlow");
						int trail = GetEntPropEnt(nade, Prop_Data, "m_pGlowTrail");
						if(i != glow && i != trail) AcceptEntityInput(i, "Kill");
					}
				}
			}
		}
	}
	return;
}