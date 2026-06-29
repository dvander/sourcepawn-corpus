#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

// ---- Engine flags ---------------------------------------------------------------
#define EF_BONEMERGE            (1 << 0)
#define EF_NOSHADOW             (1 << 4)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_PARENT_ANIMATES      (1 << 9)

new Handle:attachments_array = INVALID_HANDLE;
new gItem[MAXPLAYERS+1];
new bool:delete_enabled[MAXPLAYERS+1] = false;
new gLink[MAXPLAYERS+1];

new gClass1[MAXPLAYERS+1];
new gClass2[MAXPLAYERS+1];
new gClass3[MAXPLAYERS+1];
new gClass4[MAXPLAYERS+1];
new gClass5[MAXPLAYERS+1];
new gClass6[MAXPLAYERS+1];
new gClass7[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name		= "All For One",
	author	  	= "Master Xykon",
	description = "Play as all TF2 classes at the same time",
	version	 	= "1.0",
	url		 	= ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_afo", AFO, "All For One");
	RegConsoleCmd("sm_all", AFO, "All For One");
	RegConsoleCmd("sm_nfo", NFO, "None For One");
	RegConsoleCmd("sm_none", NFO, "None For One");
}

public Action:AFO(client, args)
{
	NFO(client, client);

	new pClass = TF2_GetPlayerClass(client);
					
	if(pClass == TFClass_Scout)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/pyro.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
	}
	
	else if(pClass == TFClass_Soldier)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/pyro.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
	}
	
	else if(pClass == TFClass_Pyro)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
	}
	
	else if(pClass == TFClass_DemoMan)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/pyro.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
	}
	
	else if(pClass == TFClass_Heavy)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/pyro.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
	}
	
	else if(pClass == TFClass_Engineer)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/pyro.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
	}
	
	else if(pClass == TFClass_Medic)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
	}
	
	else if(pClass == TFClass_Sniper)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/spy.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/heavy.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/pyro.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
	}
	
	else if(pClass == TFClass_Spy)
	{	
		gClass1[client] = Attachable_CreateAttachable(client, client, "models/player/engineer.mdl");
		gClass2[client] = Attachable_CreateAttachable(client, client, "models/player/demo.mdl");
		gClass3[client] = Attachable_CreateAttachable(client, client, "models/player/medic.mdl");
		gClass4[client] = Attachable_CreateAttachable(client, client, "models/player/scout.mdl");
		gClass5[client] = Attachable_CreateAttachable(client, client, "models/player/pyro.mdl");
		gClass6[client] = Attachable_CreateAttachable(client, client, "models/player/sniper.mdl");
		gClass7[client] = Attachable_CreateAttachable(client, client, "models/player/soldier.mdl");
	}
}

public Action:NFO(client, args)
{
	Attachable_UnhookEntity(client, gClass1[client]);
	Attachable_UnhookEntity(client, gClass2[client]);
	Attachable_UnhookEntity(client, gClass3[client]);
	Attachable_UnhookEntity(client, gClass4[client]);
	Attachable_UnhookEntity(client, gClass5[client]);
	Attachable_UnhookEntity(client, gClass6[client]);
	Attachable_UnhookEntity(client, gClass7[client]);
}

stock CAttach(child, parent, client, String:modelname[]) {
	if (attachments_array == INVALID_HANDLE) attachments_array = CreateArray(2);
	if (!IsValidEntity(child)) return false;
	if (!IsValidEntity(parent)) return false;
	new link = CGetLink(child);
	if (link == -1 || !IsValidEntity(link)) link = CAddLink(child, client, modelname);
	if (link == -1 || !IsValidEntity(link)) {
		decl String:Classname[128];
		if (GetEdictClassname(child, Classname, sizeof(Classname))) ThrowError("Unable to create link for entity %s", Classname);
		else ThrowError("Unable to create link for unknown entity");
		return false;
	}
	
	new String:name[16];
	Format(name, sizeof(name), "target%i", parent);
	DispatchKeyValue(parent, "targetname", name);

	new String:name2[32];
	GetEntPropString(parent, Prop_Data, "m_iName", name2, sizeof(name2));
	DispatchKeyValue(link, "parentname", name2);
	
	
	SetVariantString(name2);
	AcceptEntityInput(link, "SetParent", link, link, 0);
	
	SetVariantString("head");
	AcceptEntityInput(link, "SetParentAttachment", link, link, 0);
	
	return true;
}

stock CDetach(ent) {
	if (attachments_array == INVALID_HANDLE) attachments_array = CreateArray(2);
	
	if (!IsValidEntity(ent)) return false;
	
	new link = CGetLink(ent);
	if (link != -1) {
		AcceptEntityInput(ent, "SetParent", -1, -1, 0);
		if (IsValidEntity(link)) AcceptEntityInput(link, "kill");
		for (new i = 0; i < GetArraySize(attachments_array); i++) {
			new ent2 = GetArrayCell(attachments_array, i);
			if (ent == ent2) RemoveFromArray(attachments_array, i);
		}
		
		return true;
	}
	return false;
}

stock CGetLink(ent) {
	for (new i = 0; i < GetArraySize(attachments_array); i++) {
		new ent2 = GetArrayCell(attachments_array, i);
		if (ent == ent2) return (GetArrayCell(attachments_array, i, 1));
	}
	return -1;
}

stock CAddLink(ent, client, String:modelname[]) {
	new String:name_ent[16]; 
	Format(name_ent, sizeof(name_ent), "target%i", ent);
	DispatchKeyValue(ent, "targetname", name_ent);

	new link = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(link)) {
		new String:name_link[16]; 
		Format(name_link, sizeof(name_link), "target%i", link);
		DispatchKeyValue(link, "targetname", name_link);
		
		DispatchKeyValue(link, "classname", "prop_dynamic_override");
		DispatchKeyValue(link, "spawnflags", "1");
		
		SetEntProp(link, Prop_Send, "m_CollisionGroup",	   11);
		
		SetEntProp(link, Prop_Send, "m_fEffects",				EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
		
		new pClass = TF2_GetPlayerClass(client);
					
		if(pClass == TFClass_Scout)
		{	
			SetEntityModel(link, "models/player/engineer.mdl");
		}
		else if(pClass == TFClass_Engineer)
		{
			SetEntityModel(link, "models/player/soldier.mdl");
		}
		else if(pClass == TFClass_Soldier)
		{
			SetEntityModel(link, "models/player/spy.mdl");
		}
		else if(pClass == TFClass_Spy)
		{
			SetEntityModel(link, "models/player/heavy.mdl");
		}
		else if(pClass == TFClass_Heavy)
		{
			SetEntityModel(link, "models/player/sniper.mdl");
		}
		else if(pClass == TFClass_Sniper)
		{
			SetEntityModel(link, "models/player/demo.mdl");
		}
		else if(pClass == TFClass_DemoMan)
		{
			SetEntityModel(link, "models/player/medic.mdl");
		}
		else if(pClass == TFClass_Medic)
		{
			SetEntityModel(link, "models/player/pyro.mdl");
		}
		else if(pClass == TFClass_Pyro)
		{
			SetEntityModel(link, "models/player/scout.mdl");
		}
		
		new iTeam = GetClientTeam(client);
		SetEntProp(link, Prop_Send, "m_nSkin",	(iTeam-2));
		
		SetVariantString(name_link);
		AcceptEntityInput(ent, "SetParent", ent, ent, 0);
		
		SetVariantString("head");
		AcceptEntityInput(ent, "SetParentAttachment", ent, ent, 0);
		
		new index = PushArrayCell(attachments_array, ent);
		SetArrayCell(attachments_array, index, link, 1);
		
		gLink[client] = link;
		
		return link;
	}
	return -1;
}

stock Attachable_CreateAttachable(client, parent, String:modelname[])
{
	new iTeam = GetClientTeam(client);
	gItem[client] = CreateEntityByName("prop_dynamic_override");
	
	if (IsValidEdict(gItem[client]))
	{
		SetEntProp(gItem[client], Prop_Send, "m_nSkin",				(iTeam-2));
		SetEntProp(gItem[client], Prop_Send, "m_CollisionGroup",	   11);
		
		SetEntProp(gItem[client], Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
		
		DispatchKeyValue(gItem[client], "model", modelname);
		
		DispatchSpawn(gItem[client]);
		ActivateEntity(gItem[client]);
		AcceptEntityInput(gItem[client], "Start");
		
		CAttach(gItem[client], parent, client, modelname);
		
		delete_enabled[client] = true;
	}
	
	return gItem[client];
}

stock Attachable_UnhookEntity(client, ent)
{
	if (delete_enabled[client] == true)
	{
		CDetach(ent);
		AcceptEntityInput(ent, "KillHierarchy");
	}
}