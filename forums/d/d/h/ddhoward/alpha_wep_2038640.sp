#include <sourcemod>
#include <tf2_stocks> 

public Plugin:myinfo = {
	name = "WepAlphanator",
	author = "Assyrian/Nergal & Derek Howard",
	description = "makes weapons transparent",
	version = "1.0.0.3",
	url = "http://www.sourcemod.net/"
} 
 
public OnPluginStart() {
	RegAdminCmd("sm_alpha_wep", Command_SetWepAlpha, ADMFLAG_GENERIC);
}

public Action:Command_SetWepAlpha(client, args) {
	new numargs = GetCmdArgs();
	if (numargs != 2) {
		ReplyToCommand(client, "Usage: \"sm_alpha_wep [target] [value]\"");
		return Plugin_Handled;
	}
	new target[MAXPLAYERS];
	decl String:target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
	new numtargets;
	decl String:arg1[64]; arg1[0] = '\0';
	new bool:tn_is_ml;
	GetCmdArg(1, arg1, sizeof(arg1));
	if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, numtargets);
		return Plugin_Handled;
	}
	decl String:arg2[4]; arg2[0] = '\0';
	GetCmdArg(2, arg2, sizeof(arg2));
	new alpha = StringToInt(arg2);
	if (alpha > 255 || alpha < 0) {
		ReplyToCommand(client, "[SM] Second argument must be between 0 and 255.");
		return Plugin_Handled;
	}
	for (new currenttarget = 0; currenttarget < numtargets; currenttarget++) {
		for (new wep = 0; wep < 5; wep++) { 
			new entity = GetPlayerWeaponSlot(target[currenttarget], wep); 
			if (entity != -1) { 
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR); 
				SetEntityRenderColor(entity, _, _, _, alpha); 
			}
		}
	}
	LogAction(client, -1, "\"%L\" set weapon transparency to %i on %s.", client, alpha, target_name);
	ShowActivity2(client, "[SM] ", "Set weapon transparency to %i on %s.", alpha, target_name);
	return Plugin_Handled;
}