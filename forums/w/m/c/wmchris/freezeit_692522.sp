#include <sourcemod>
#include <sdktools> 
   
public Plugin:myinfo =
{
	name = "Entity Freezer",
	author = "Krim",
	description = "Freezes Entitys",
	version = "1.0.0.0",
	url = ""
};
 
public OnPluginStart()
{
	RegAdminCmd("sm_freezeit", Command_Freezeit, ADMFLAG_SLAY,"Point and Go :)");
	RegAdminCmd("sm_unfreezeit", Command_UnFreezeit, ADMFLAG_SLAY,"Point and Go :)"); 
}

 
public Action:Command_Freezeit(Client,args)
{
    	PrintToChat(Client, "[Freezed Entity]");
	decl Ent;       
	Ent = GetClientAimTarget(Client, false);

    	SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
	SetEntityMoveType(Ent, MOVETYPE_NONE);  
	return Plugin_Handled;
}

public Action:Command_UnFreezeit(Client,args)
{
    	PrintToChat(Client, "[Unfreezed Entity]");
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
    	SetEntProp(Ent, Prop_Data, "m_takedamage", 2, 1)
	SetEntityMoveType(Ent, MOVETYPE_VPHYSICS); 
	return Plugin_Handled;
}
