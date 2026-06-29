//Entity commands by Anose
//Version 1.1.0.8
//Also Helped by No-Half-Measures
//Contact: anose.com@gmail.com

//Include:
#include <sourcemod>
#include <sdktools>

#define VERSION 		"1.1.0.8"

static String:CopiedPropModel[255][255];

public Action:Command_info(Client, Args)
{
PrintToConsole(Client, "Valid commands are:");
PrintToConsole(Client, "+move/-move: moves the entity.");
PrintToConsole(Client, "sm_freezeit: Freezes the entity.");
PrintToConsole(Client, "sm_unfreeze: Unfreezes the entity.");
PrintToConsole(Client, "sm_modelinfo: Prints modelname & location.");
PrintToConsole(Client, "sm_remove: Removes entity.");
PrintToConsole(Client, "sm_modelme: changes your model to <aimtarget's model>.");
PrintToConsole(Client, "sm_colision <on-off>: Set's solidity.");
PrintToConsole(Client, "sm_rotate <degrees>: Rotates a prop.");
PrintToConsole(Client, "sm_color <color>: Changes color.");
PrintToConsole(Client, "sm_copy: Copies the prop");
PrintToConsole(Client, "sm_paste: Pastes the prop");
PrintToConsole(Client, "sm_skin <num>: set's skin");
PrintToConsole(Client, "sm_advcolor <r><g><b><a>: Advanced colorizing");
}
public Action:Command_advcolorize(Client, Args)
{
	if(Args < 3 || Args > 3)
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Usage: sm_advcolor <red> <green> <blue> <alpha>");
		return Plugin_Handled;
	}
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	new Ent = GetClientAimTarget(Client, false);
	//Get args
	decl String:Color1[255];
	GetCmdArg(1, Color1, sizeof(Color1));
	decl String:Color2[255];
	GetCmdArg(2, Color2, sizeof(Color2));
	decl String:Color3[255];
	GetCmdArg(3, Color3, sizeof(Color3));
	decl String:Color4[255];
	GetCmdArg(4, Color4, sizeof(Color4));
	//index
	new Color1int = StringToInt(Color1);
	new Color2int = StringToInt(Color2);
	new Color3int = StringToInt(Color3);
	new Color4int = StringToInt(Color4);
	if(IsValidEntity(Ent))
	{
		SetEntityRenderColor(Ent, Color1int, Color2int, Color3int, Color4int);
		PrintToChat(Client, "\x04[EntityCommands] - \x01Prop color has been set to %d %d %d %d", Color1int, Color2int, Color3int, Color4int);
	}
	else
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01You are not looking at anything");
	}
	return Plugin_Handled;
}
public Action:Command_freeze(Client, Args)
{
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
	
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	
	if(IsValidEntity(Ent))
	{
			AcceptEntityInput(Ent, "DisableMotion");
			new Float:stopspeed[3] = {0.0, 0.0, 0.0};
			
			TeleportEntity(Ent, NULL_VECTOR, NULL_VECTOR, stopspeed);
			
			PrintToChat(Client, "\x04[EntityCommands] - \x01Froze entity");
	}
	else
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01You are not looking at anything!");
	}
	return Plugin_Handled;
}

public Action:Command_unfreeze(Client,args)
{
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
	
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	
	if(IsValidEntity(Ent))
	{
			AcceptEntityInput(Ent, "EnableMotion");
			
			PrintToChat(Client, "\x04[EntityCommands] - \x01Unfroze entity");
	}
	else
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01You are not looking at anything!");
	}
	return Plugin_Handled;
}

public Action:Command_endmove(Client,args)
{
	//Declarate:
	decl MoveEnt;
	MoveEnt = GetClientAimTarget(Client, false);
	if(IsValidEntity(MoveEnt))
	{
	DispatchKeyValue(MoveEnt, "parentname", "none")
	AcceptEntityInput(MoveEnt, "SetParent", -1, -1, 0)
	SetEntityRenderFx(MoveEnt, RENDERFX_NONE); //Remove effect	
	TeleportEntity(MoveEnt, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR); //tele
	}
}
public Action:Command_move(Client,args)
{
	decl MoveEnt;
	MoveEnt = GetClientAimTarget(Client, false);
	new String:tName[128]
	Format(tName, sizeof(tName), "target%i", Client)
	DispatchKeyValue(Client, "targetname", tName)
	
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	//SetParent
	if(IsValidEntity(MoveEnt))
    {
	DispatchKeyValue(MoveEnt, "parentname", tName)
	SetVariantString(tName)
	AcceptEntityInput(MoveEnt, "SetParent", MoveEnt, MoveEnt, 0)
	SetEntityRenderFx(MoveEnt, RENDERFX_HOLOGRAM); //Effect
	}
	else
	{
	PrintToChat(Client, "\x04You are not looking at anything!");
	}
	return Plugin_Handled;
}

public Action:Command_modelinfo(Client,args)
{
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
	if(IsValidEntity(Ent))
    {
	//Model
	decl String:modelname[128];
	GetEntPropString(Ent, Prop_Data, "m_ModelName", modelname, 128);
	//ClassName
	new String:StoreClass[33];
	GetEdictClassname(Ent, StoreClass, 33);
	//Convert to int
	//new printclass = StringToInt(StoreClass);
		
	PrintToChat(Client, "\x04Model name:\x01 %s", modelname);
	PrintToChat(Client, "\x04Class name:\x01 %s", StoreClass);
	}
	else
	{
	PrintToChat(Client, "\x04You are not looking at anything!");
	}
}

public Action:Command_remove(Client,args)
{
	//Declarate:
	decl entrem;
	entrem = GetClientAimTarget(Client, false);
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	if(IsValidEntity(entrem))
    {
	RemoveEdict(entrem);
	PrintToChat(Client, "\x04Successfully removed entity.");
	}
	else
	{
	PrintToChat(Client, "\x04You are not looking at anything!");
	}
	return Plugin_Handled;
}

public Action:Command_modelme(Client,args)
{
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
	if(IsValidEntity(Ent))
	{
	decl String:modelname[128];
	GetEntPropString(Ent, Prop_Data, "m_ModelName", modelname, 128);
	SetEntityModel(Client, modelname)
	PrintToChat(Client, "\x04Changed your model to:\x01 %s", modelname);
	}
	else
	{
	PrintToChat(Client, "\x04You are not looking at anything!");
	}
}

public Action:Command_solid(Client,args)
{
	decl Ent;
	Ent = GetClientAimTarget(Client,false);
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	if(IsValidEntity(Ent))
	{
			decl String:toggle[255];
			GetCmdArgString(toggle, sizeof(toggle));
			if(StrEqual(toggle, "off", false))
			{
				SetEntProp(Ent, Prop_Data, "m_CollisionGroup", 1);
				PrintToChat(Client, "\x04[EntityCommands] - \x01The prop is now unsolid");
			}
			else if(StrEqual(toggle, "on", false))
			{
				SetEntProp(Ent, Prop_Data, "m_CollisionGroup", 0);
				PrintToChat(Client, "\x04[EntityCommands] - \x01The prop is now solid");
			}
	}
	else
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01You are not looking at anything!");
	}
	return Plugin_Handled;
}

public Action:Command_rotate(Client,args)
{
	decl Ent;
	Ent = GetClientAimTarget(Client,false);
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	if(IsValidEntity(Ent))
	{
			EmitSoundToAll("npc/scanner/scanner_nearmiss1.wav", Ent, 0, 70);
			new Float:GetAngles[3];
			GetEntPropVector(Ent, Prop_Data, "m_angRotation", GetAngles);
			new Float:Angles[3];
			Angles[0] = GetAngles[0];
			Angles[1] = GetAngles[1];
			Angles[2] = GetAngles[2];
			
			new String:xangle[10];
			GetCmdArg(1, xangle, sizeof(xangle))
			
			new intxangle = StringToInt(xangle);
			
			Angles[0] += 0;
			Angles[1] += intxangle;
			Angles[2] += 0;
			
			TeleportEntity(Ent, NULL_VECTOR, Angles, NULL_VECTOR);
			
			PrintToChat(Client, "\x04[EntityCommands] - \x01Rotated Prop by %d", intxangle);
	}
	else
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01You are not looking at anything!");
	}
	return Plugin_Handled;
}
public Action:Command_setskin(Client,args)
{
	if (IsClientInGame(Client) && IsPlayerAlive(Client))
	{
		new PlayerEnt = GetClientAimTarget(Client, true);
		if(IsValidEntity(PlayerEnt))
		{
			PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
			return Plugin_Handled;
		}
		decl Ent;
		Ent = GetClientAimTarget(Client, false);
		new String:skin[10]
		GetCmdArg(1, skin, sizeof(skin))
		new intskin = StringToInt(skin);
		
		if(IsValidEntity(Ent))
		{
				DispatchKeyValue(Ent, "skin", skin);
				PrintToChat(Client, "\x04[EntityCommands] - \x01Changed model skin to %d", intskin);
		}
		else
		{
			PrintToChat(Client, "\x04[EntityCommands] - \x01You are not looking at anything");
		}
	}
	return Plugin_Handled;
}
public Action:Command_setcolor(Client,args)
{
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
	decl String:Color[255];
	GetCmdArgString(Color, sizeof(Color));
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	if(IsValidEntity(Ent))
	{
	if(StrEqual(Color, "red", false))
	{
		SetEntityRenderColor(Ent, 255, 0, 0);
	}
	else if(StrEqual(Color, "orange", false))
	{
		SetEntityRenderColor(Ent, 218, 165, 32);
	}
	else if(StrEqual(Color, "green", false))
	{
		SetEntityRenderColor(Ent, 50, 205, 50);
	}
	else if(StrEqual(Color, "white", false))
	{
		SetEntityRenderColor(Ent, 255, 255, 255);
	}
	else if(StrEqual(Color, "yellow", false))
	{
		SetEntityRenderColor(Ent, 255, 255, 0);
	}
	else if(StrEqual(Color, "grey", false))
	{
		SetEntityRenderColor(Ent, 139, 137, 137);
	}
	else if(StrEqual(Color, "blue", false))
	{
		SetEntityRenderColor(Ent, 0, 0, 255);
	}
	}
	else
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01You are not looking at anything");
	}
	return Plugin_Handled;
}
public Action:Command_copy(Client,args)
{
	decl String:modelname[128];
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
	new PlayerEnt = GetClientAimTarget(Client, true);
	if(IsValidEntity(PlayerEnt))
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01Can not use this command on players!");
		return Plugin_Handled;
	}
	if(IsValidEntity(Ent))
	{
		GetEntPropString(Ent, Prop_Data, "m_ModelName", modelname, 128);
		PrecacheModel(modelname,true);
		CopiedPropModel[Client] = modelname;
		
		PrintToChat(Client, "\x04[EntityCommands] - \x01You copy a prop \x04<%s>.", modelname);
		PrintToChat(Client, "\x04[EntityCommands] - \x01Type \x04/paste\x01 to paste a prop you copied now.");
	}
	else
	{
		PrintToChat(Client, "\x04[EntityCommands] - \x01You are not looking at anything.");
	}
	return Plugin_Handled;
}
public Action:Command_paste(Client,args)
{	
	new Float:EyeAng[3];
	GetClientEyeAngles(Client, EyeAng);
	new Float:ForwardVec[3];
	GetAngleVectors(EyeAng, ForwardVec, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(ForwardVec, 100.0);
	ForwardVec[2] = -65.0;
	new Float:EyePos[3];
	GetClientEyePosition(Client, EyePos);
	new Float:AbsAngle[3];
	GetClientAbsAngles(Client, AbsAngle);
	
	new Float:SpawnAnglesspawner[3];
	SpawnAnglesspawner[1] = EyeAng[1];
	new Float:SpawnOriginspawner[3];
	AddVectors(EyePos, ForwardVec, SpawnOriginspawner);
	
	new EntityIndex = CreateEntityByName("prop_dynamic");
	if (EntityIndex == -1)
	{
		return;
	}
	DispatchKeyValue(EntityIndex, "model", CopiedPropModel[Client]);
	DispatchKeyValue(EntityIndex, "solid", "6");
	
	DispatchSpawn(EntityIndex);
	ActivateEntity(EntityIndex);
	
	PrintToChat(Client, "\x04[EntityCommands] - \x01Pasted.");
	
	TeleportEntity(EntityIndex, SpawnOriginspawner, SpawnAnglesspawner, NULL_VECTOR);
}
//info:
public Plugin:myinfo =
{
	
	//Initation:
	name = "Entity commands",
	author = "Anose",
	description = "Entity commands.",
	version = VERSION,
	url = ""
}

//Instal:
public OnMapStart()
{
	//Precache:
	PrecacheSound("npc/scanner/scanner_nearmiss1.wav", true);
}
public OnPluginStart()
{
RegAdminCmd("sm_printcmds", Command_info, ADMFLAG_SLAY, "Prints commands to client.");
RegAdminCmd("sm_freezeit", Command_freeze, ADMFLAG_SLAY, "Disables motion.");
RegAdminCmd("sm_unfreeze", Command_unfreeze, ADMFLAG_SLAY, "Enables motion.");
RegAdminCmd("+move", Command_move, ADMFLAG_SLAY, "moves entity.");
RegAdminCmd("-move", Command_endmove, ADMFLAG_SLAY, "moves entity.");
RegAdminCmd("sm_entityinfo", Command_modelinfo, ADMFLAG_SLAY, "prints info of prop.");
RegAdminCmd("sm_remove", Command_remove, ADMFLAG_SLAY, "removes entity.");
RegAdminCmd("sm_modelme", Command_modelme, ADMFLAG_SLAY, "set's your model <aim target>");
RegAdminCmd("sm_colision", Command_solid, ADMFLAG_SLAY, "set's solidity");
RegAdminCmd("sm_rotate", Command_rotate, ADMFLAG_SLAY, "rotates a prop");
RegAdminCmd("sm_skin", Command_setskin, ADMFLAG_SLAY, "set's skin");
RegAdminCmd("sm_color", Command_setcolor, ADMFLAG_SLAY, "set's color");
RegAdminCmd("sm_advcolor", Command_advcolorize, ADMFLAG_SLAY, "more advanced color changer");
RegAdminCmd("sm_copy", Command_copy, ADMFLAG_SLAY, "copies");
RegAdminCmd("sm_paste", Command_paste, ADMFLAG_SLAY, "pastes");

//Version:
CreateConVar("entitycommands_version", VERSION, "Entity commands version.", FCVAR_PLUGIN|FCVAR_NOTIFY);
//Print:
PrintToConsole(0, "Entity commands by Anose&No-Half-Measures loaded successfully, Version: %s.",VERSION);
}