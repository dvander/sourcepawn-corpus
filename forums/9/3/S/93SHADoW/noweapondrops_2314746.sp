
#pragma semicolon 1

#include <tf2>
#undef REQUIRE_PLUGIN
#tryinclude <freak_fortress_2>
#define REQUIRE_PLUGIN

#pragma newdecls required

#undef REQUIRE_PLUGIN
#tryinclude <saxtonhale>
#define REQUIRE_PLUGIN

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>


#if defined _VSH_included
bool isVSH;
#endif

#if defined _FF2_included
bool isFF2;
#endif

public Plugin myinfo = {
	name = "VSH/FF2: Block weapon drops",
	author = "SHADoW NiNE TR3S / sarysa",
	description="Prevents tf_dropped_weapon, therefore, no weapon drops",
	version="1.1",
};

public void OnPluginStart()
{	
	#if defined _VSH_included
	isVSH=LibraryExists("saxtonhale");
	#endif

	#if defined _FF2_included	
	isFF2=LibraryExists("freak_fortress_2");
	#endif
}

// sarysa's fix for the new weapon drop stuff
public void OnEntityCreated(int entity, const char[] classname)
{

	if(FindConVar("tf_dropped_weapon_lifetime").FloatValue && !StrContains(classname, "tf_dropped_weapon"))
	{
		#if defined _VSH_included
		if(isVSH)
		{
			if(!VSH_IsSaxtonHaleModeEnabled())
			{
				return;
			}
		}
		#endif
			
		#if defined _FF2_included	
		if(isFF2)
		{
			if(!FF2_IsFF2Enabled())
			{
				return;
			}
		}
		#endif
	
		AcceptEntityInput(entity, "kill");
		return;
	}
}