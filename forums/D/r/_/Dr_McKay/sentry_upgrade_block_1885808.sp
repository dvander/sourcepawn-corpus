#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name		= "[TF2] Level 1 Sentries Only",
	description	= "Only allows level 1 sentries",
	author		= "Dr. McKay",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
}

public OnGameFrame() {
	new entity = -1;
	while((entity = FindEntityByClassname(entity, "obj_sentrygun")) != -1) {
		SetEntProp(entity, Prop_Send, "m_iUpgradeMetal", 0);
	}
}