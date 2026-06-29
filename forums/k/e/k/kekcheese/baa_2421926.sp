/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Basic Admin Announcements
 *
 * Copyright 2016 Cheese. All Rights Reserved
 * =============================================================================
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#pragma semicolon 1

#include <sourcemod>
#include <colors>

#define CVAR_COMMAND1		0
#define CVAR_TEXT1			1
#define CVAR_COMMAND2		2
#define CVAR_TEXT2		3
#define CVAR_COMMAND3		4
#define CVAR_TEXT3	5
#define CVAR_COMMAND4	6
#define CVAR_TEXT4	7
#define CVAR_COMMAND5	8
#define CVAR_TEXT5	9
#define CVAR_COMMAND6	10
#define CVAR_TEXT6	11
#define CVAR_NUM_CVARS		12

#define VERSION		"1.0"

new Handle:g_cvars[CVAR_NUM_CVARS];

public Plugin:myinfo = {
	name = "Basic Admin Announcements",
	author = "Cheese",
	description = "Basic admin announcements with color support",
	version = VERSION,
	url = "http://www.keksurf.com"
};

public OnPluginStart() {
	g_cvars[CVAR_COMMAND1] = CreateConVar(
	"sm_baa_command_1",
	"sm_r1",
	"Command for first text announcement",
	FCVAR_PLUGIN);

	g_cvars[CVAR_TEXT1] = CreateConVar(
	"sm_baa_text_1",
	"{blue}This is a test announcement for command 1",
	"Text announcement connected to sm_baa_command_1",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_COMMAND2] = CreateConVar(
	"sm_baa_command_2",
	"sm_r2",
	"Command for first text announcement",
	FCVAR_PLUGIN);

	g_cvars[CVAR_TEXT2] = CreateConVar(
	"sm_baa_text_2",
	"{blue}This is a test announcement for command 2",
	"Text announcement connected to sm_baa_command_2",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_COMMAND3] = CreateConVar(
	"sm_baa_command_3",
	"sm_r3",
	"Command for first text announcement",
	FCVAR_PLUGIN);

	g_cvars[CVAR_TEXT3] = CreateConVar(
	"sm_baa_text_3",
	"{blue}This is a test announcement for command 3",
	"Text announcement connected to sm_baa_command_3",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_COMMAND4] = CreateConVar(
	"sm_baa_command_4",
	"sm_r4",
	"Command for first text announcement",
	FCVAR_PLUGIN);

	g_cvars[CVAR_TEXT4] = CreateConVar(
	"sm_baa_text_4",
	"{blue}This is a test announcement for command 4",
	"Text announcement connected to sm_baa_command_4",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_COMMAND5] = CreateConVar(
	"sm_baa_command_5",
	"sm_r5",
	"Command for first text announcement",
	FCVAR_PLUGIN);

	g_cvars[CVAR_TEXT5] = CreateConVar(
	"sm_baa_text_5",
	"{blue}This is a test announcement for command 5",
	"Text announcement connected to sm_baa_command_5",
	FCVAR_PLUGIN);
	
	g_cvars[CVAR_COMMAND6] = CreateConVar(
	"sm_baa_command_6",
	"sm_r6",
	"Command for first text announcement",
	FCVAR_PLUGIN);

	g_cvars[CVAR_TEXT6] = CreateConVar(
	"sm_baa_text_6",
	"{blue}This is a test announcement for command 6",
	"Text announcement connected to sm_baa_command_6",
	FCVAR_PLUGIN);

	
	AutoExecConfig(true);
	decl String:cmd1[16];
	decl String:cmd2[16];
	decl String:cmd3[16];
	decl String:cmd4[16];
	decl String:cmd5[16];
	decl String:cmd6[16];
	
	GetConVarString(g_cvars[CVAR_COMMAND1], cmd1, sizeof(cmd1));
	GetConVarString(g_cvars[CVAR_COMMAND2], cmd2, sizeof(cmd2));
	GetConVarString(g_cvars[CVAR_COMMAND3], cmd3, sizeof(cmd3));
	GetConVarString(g_cvars[CVAR_COMMAND4], cmd4, sizeof(cmd4));
	GetConVarString(g_cvars[CVAR_COMMAND5], cmd5, sizeof(cmd5));
	GetConVarString(g_cvars[CVAR_COMMAND6], cmd6, sizeof(cmd6));
	
	RegAdminCmd(cmd1, Command_Broadcast1, ADMFLAG_GENERIC);
	RegAdminCmd(cmd2, Command_Broadcast2, ADMFLAG_GENERIC);
	RegAdminCmd(cmd3, Command_Broadcast3, ADMFLAG_GENERIC);
	RegAdminCmd(cmd4, Command_Broadcast4, ADMFLAG_GENERIC);
	RegAdminCmd(cmd5, Command_Broadcast5, ADMFLAG_GENERIC);
	RegAdminCmd(cmd6, Command_Broadcast6, ADMFLAG_GENERIC);
}



public Action:Command_Broadcast1(client, args) {
	decl String:text[288];
	GetConVarString(g_cvars[CVAR_TEXT1], text, sizeof(text));
	CPrintToChatAll(text);
	return Plugin_Handled;
}

public Action:Command_Broadcast2(client, args) {
	decl String:text[288];
	GetConVarString(g_cvars[CVAR_TEXT2], text, sizeof(text));
	CPrintToChatAll(text);
	return Plugin_Handled;
}

public Action:Command_Broadcast3(client, args) {
	decl String:text[288];
	GetConVarString(g_cvars[CVAR_TEXT3], text, sizeof(text));
	CPrintToChatAll(text);
	return Plugin_Handled;
}

public Action:Command_Broadcast4(client, args) {
	decl String:text[288];
	GetConVarString(g_cvars[CVAR_TEXT4], text, sizeof(text));
	CPrintToChatAll(text);
	return Plugin_Handled;
}

public Action:Command_Broadcast5(client, args) {
	decl String:text[288];
	GetConVarString(g_cvars[CVAR_TEXT5], text, sizeof(text));
	CPrintToChatAll(text);
	return Plugin_Handled;
}

public Action:Command_Broadcast6(client, args) {
	decl String:text[288];
	GetConVarString(g_cvars[CVAR_TEXT6], text, sizeof(text));
	CPrintToChatAll(text);
	return Plugin_Handled;
}