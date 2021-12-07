#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Look At It",
	author = "The Count",
	description = "",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071"
}

public OnPluginStart(){
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_look", Cmd_Look, ADMFLAG_SLAY, "Look where I look.");
	RegAdminCmd("sm_lookat", Cmd_LookAt, ADMFLAG_SLAY, "Look at someone.");
}

public Action:Cmd_Look(client, args){
	if(args != 1){
		PrintToChat(client, "\x01[SM] Usage: !look [CLIENT]");
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client)){
		PrintToChat(client, "\x01[SM] Must be alive.");
		return Plugin_Handled;
	}
	new String:arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new Float:flPos[3], Float:flAng[3], Float:location[3];
	GetClientEyePosition(client, flPos);
	GetClientEyeAngles(client, flAng);
	new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnoreSelf, client);
	if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace)){
		TR_GetEndPosition(location, hTrace);
	}else{
		PrintToChat(client, "\x01[SM] No end position found!");
		CloseHandle(hTrace);
		return Plugin_Handled;
	}
	CloseHandle(hTrace);
	for(new i=0;i<target_count;i++){
		LookAtPoint(target_list[i], location);
	}
	PrintToChat(client, "[SM] Target(s) forced to look at location.");
	return Plugin_Handled;
}

public Action:Cmd_LookAt(client, args){
	if(args != 2){
		PrintToChat(client, "\x01[SM] Usage: !lookat [CLIENT] [TARGET]");
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client)){
		PrintToChat(client, "\x01[SM] Must be alive.");
		return Plugin_Handled;
	}
	new String:arg1[MAX_NAME_LENGTH], String:arg2[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new locator = FindTarget(client, arg2, false, false);
	if(locator == -1 || !IsPlayerAlive(locator)){
		PrintToChat(client, "[SM] Target must be alive.");
		return Plugin_Handled;
	}
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for(new i=0;i<target_count;i++){
		LookAtTarget(target_list[i], locator);
	}
	GetClientName(locator, arg2, sizeof(arg2));
	PrintToChat(client, "\x01[SM] Target(s) forced to look at \x04%s\x01.", arg2);
	return Plugin_Handled;
}

stock LookAtTarget(any:client, any:target){
	new Float:angles[3], Float:clientEyes[3], Float:targetEyes[3], Float:resultant[3];
	GetClientEyePosition(client, clientEyes);
	GetClientEyePosition(target, targetEyes);
	MakeVectorFromPoints(targetEyes, clientEyes, resultant);
	GetVectorAngles(resultant, angles);
	if(angles[0] >= 270){
		angles[0] -= 270;
		angles[0] = (90-angles[0]);
	}else{
		if(angles[0] <= 90){
			angles[0] *= -1;
		}
	}
	angles[1] -= 180;
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
}

stock LookAtPoint(any:client, Float:point[3]){
	new Float:angles[3], Float:clientEyes[3], Float:resultant[3];
	GetClientEyePosition(client, clientEyes);
	MakeVectorFromPoints(point, clientEyes, resultant);
	GetVectorAngles(resultant, angles);
	if(angles[0] >= 270){
		angles[0] -= 270;
		angles[0] = (90-angles[0]);
	}else{
		if(angles[0] <= 90){
			angles[0] *= -1;
		}
	}
	angles[1] -= 180;
	TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
}

public bool:TraceFilterIgnoreSelf(entity, contentsMask, any:client)
{
	if(entity == client)
	{
		return false;
	}
	
	return true;
}