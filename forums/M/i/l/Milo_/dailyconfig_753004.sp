/**
 * Application:      dailyconfig.smx
 * Author:           Milo <milo@corks.nl>
 * Target platform:  Sourcemod 1.2.0 + Metamod 1.7.0 + Team Fortress 2 (20090417)
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#include <sourcemod>

#define VERSION    "1.2"

#define PATH_PREFIX_ACTUAL    "cfg/"
#define PATH_PREFIX_VISIBLE   "dailyconfig/"

new Handle:cvarOffset         = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "Daily config package",
	author      = "Milo",
	description = "Allows you to use seperate config files for each day of the week.",
	version     = VERSION,
	url         = "http://sourcemod.corks.nl/"
};

public OnPluginStart() {
	CreateConVar("dailyconfig_version", VERSION, "Current version of the dailyconfig plugin", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarOffset = CreateConVar("sm_dailyconfig_offset", "", "Time difference to apply to the server clock when determining today's config. Use values such as '+1' if the server's clocktime is one hour behind, or '-4' if the clock is 4 hours ahead. All invalid values will be treated as no time difference.");
	RegAdminCmd("sm_dailyconfig_clock", CMD_ShowClock, ADMFLAG_RCON|ADMFLAG_ROOT|ADMFLAG_CONFIG, "sm_dailyconfig_clock");
	createConfigFiles();
}

public Action:CMD_ShowClock(client, args) {
 	new String:datatimeStringA[128];
	new String:datatimeStringB[128];
	new String:convarDesc[128] = "No change.";
	new String:convarValue[16];
	new operand, amount;
	FormatTime(datatimeStringA, sizeof(datatimeStringA), "%A %H:%M", getAccurateTime(false));
	FormatTime(datatimeStringB, sizeof(datatimeStringB), "%A %H:%M", getAccurateTime(true));
	GetConVarString(cvarOffset, convarValue, sizeof(convarValue));
	operand = parseTimeOffsetOperation(false);
	amount  = parseTimeOffsetOperation(true);
	if (operand == '+') Format(convarDesc, sizeof(convarDesc), "Add %d hours to actual time.", amount);
	if (operand == '-') Format(convarDesc, sizeof(convarDesc), "Subtract %d hours from actual time.", amount);
	PrintToConsole(client, "Current time according to server clock : %s", datatimeStringA);
	PrintToConsole(client, "sm_dailyconfig_offset : \"%s\" (%s)", convarValue, convarDesc);
	PrintToConsole(client, "Current time after offset : %s", datatimeStringB);
	return Plugin_Handled;
}

public OnConfigsExecuted() {
	new String:configFilename[PLATFORM_MAX_PATH];
	getAppropriateConfigFile(configFilename, sizeof(configFilename), false);
	PrintToServer("Loading daily configfile \"%s\".", configFilename);
	ServerCommand("exec \"%s\"", configFilename);
}

parseTimeOffsetOperation(const bool:getAmountInsteadOfOperand=false) {
	new operand, amount;
	new String:convarValue[16];
	GetConVarString(cvarOffset, convarValue, sizeof(convarValue));
	TrimString(convarValue);
	operand = convarValue[0];
	convarValue[0] = ' ';
	TrimString(convarValue);
	amount  = StringToInt(convarValue);
	if ((operand == '+' || operand == '-') && amount > 0 && amount <= 24) {
	} else {
		operand = ' ';
		amount  = 0;
	}
	return getAmountInsteadOfOperand ? amount : operand;
}

getAccurateTime(const bool:applyDifference=true) {
	if (!applyDifference) return GetTime();
	new time = GetTime();
	new operand, amount;
	operand = parseTimeOffsetOperation(false);
	amount  = parseTimeOffsetOperation(true);
	if (operand == '+') time = time + (amount * 3600);
	if (operand == '-') time = time - (amount * 3600);
	return time;
}

getAppropriateConfigFile(String:configFile[], const length, const bool:truePath=false, const day=-1) {
	new String:configFilename[PLATFORM_MAX_PATH];
	new String:dayStr[2];
	new        dayNum;
	FormatTime(dayStr, sizeof(dayStr), "%w", getAccurateTime(true));
	if (day >= 0) dayNum = day;
	else          dayNum = StringToInt(dayStr);
	switch (dayNum) {
		case 6:  configFilename = "saturday.cfg";
		case 5:  configFilename = "friday.cfg";
		case 4:  configFilename = "thursday.cfg";
		case 3:  configFilename = "wednesday.cfg";
		case 2:  configFilename = "tuesday.cfg";
		case 1:  configFilename = "monday.cfg";
		default: configFilename = "sunday.cfg";
	}
	Format(configFile, length, "%s%s%s", (truePath ? PATH_PREFIX_ACTUAL : ""), PATH_PREFIX_VISIBLE, configFilename);
}

createConfigFiles() {
	new String:configFilename[PLATFORM_MAX_PATH];
	new Handle:fileHandle;
	// Create the dir, if it doesnt exist yet
	Format(configFilename, sizeof(configFilename), "%s%s", PATH_PREFIX_ACTUAL, PATH_PREFIX_VISIBLE);
	CreateDirectory(configFilename, FPERM_U_READ + FPERM_U_WRITE + FPERM_U_EXEC + 
	                                FPERM_G_READ + FPERM_G_WRITE + FPERM_G_EXEC + 
																	FPERM_O_READ + FPERM_O_WRITE + FPERM_O_EXEC);
	// For each day of the week
	for (new i = 0; i <= 6; i++) {
		getAppropriateConfigFile(configFilename, sizeof(configFilename), true, i);
		// Check if config exists
		if (FileExists(configFilename)) continue;
		// If it doesnt, create it
		fileHandle = OpenFile(configFilename, "w+");
		if (fileHandle != INVALID_HANDLE) {
			WriteFileLine(fileHandle, "// Configfile for this day...");
			CloseHandle(fileHandle);
		}
	}
}