//Stable By Multimod Plugins v1.02
#include <sourcemod>
#include <sdktools> 
   
public Plugin:myinfo =
{
	name = "Stable",
	author = "Multimod",
	description = "Make Entitys Stable Or Unstable.",
	version = "1.0.0.2",
	url = ""
};
 
public OnPluginStart()
{
	RegAdminCmd("sm_stable", Command_stable, ADMFLAG_SLAY,"Point and Go :)");
	RegAdminCmd("sm_unstable", Command_unstable, ADMFLAG_SLAY,"Point and Go :)"); 
}

 
public Action:Command_stable(Client,args)
{
    	PrintToChat(Client, "[STABLE]Entity Is Now Rendered Stable");
	decl Ent;       
	Ent = GetClientAimTarget(Client, false);

    	SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
	SetEntityMoveType(Ent, MOVETYPE_NONE);  
	return Plugin_Handled;
}

public Action:Command_unstable(Client,args)
{
    	PrintToChat(Client, "[STABLE]Entity Is Now Rendered Unstable");
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
    	SetEntProp(Ent, Prop_Data, "m_takedamage", 2, 1)
	SetEntityMoveType(Ent, MOVETYPE_VPHYSICS); 
	return Plugin_Handled;
}
