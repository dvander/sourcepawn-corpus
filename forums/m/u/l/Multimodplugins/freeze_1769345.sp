#include <sourcemod>
#include <sdktools> 
   
public Plugin:myinfo =
{
	name = "Freeze",
	author = "McBooRocks",
	description = "Freezes Entitys",
	version = "1.0.0.0",
	url = ""
};
 
public OnPluginStart()
{
	RegAdminCmd("sm_freeze", Command_Freeze, ADMFLAG_SLAY,"Point and Go :)");
	RegAdminCmd("sm_unfreeze", Command_UnFreeze, ADMFLAG_SLAY,"Point and Go :)"); 
}

 
public Action:Command_Freeze(Client,args)
{
    	PrintToChat(Client, "[Freezed Entity]");
	decl Ent;       
	Ent = GetClientAimTarget(Client, false);

    	SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
	SetEntityMoveType(Ent, MOVETYPE_NONE);  
	return Plugin_Handled;
}

public Action:Command_UnFreeze(Client,args)
{
    	PrintToChat(Client, "[Unfreezed Entity]");
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
    	SetEntProp(Ent, Prop_Data, "m_takedamage", 2, 1)
	SetEntityMoveType(Ent, MOVETYPE_VPHYSICS); 
	return Plugin_Handled;
}
