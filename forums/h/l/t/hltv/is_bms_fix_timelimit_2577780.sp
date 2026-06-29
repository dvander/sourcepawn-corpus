/**
 * =============================================================================
 * is-bms-fix-timelimit
 * enable changes via mp_timeleft
 *
 * is-bms-fix-timelimit (C)2018 Christian Baumann  All rights reserved.
 * =============================================================================
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
 * 
 * Changelog:
 * 1.0 First Release
 */
#include <sourcemod>
#include <sdktools>


#define VERSION "1.0"
bool g_bBlocked=true;

public Plugin:myinfo = {
	name = "is-bms-fix-timelimit",
	author = "hltv",
	description = "enable changes via mp_timeleft",
	version = VERSION,
	url = "http://is-server.de"
};

public OnPluginStart() {
	ConVar cvMpTimelimit = FindConVar("mp_timelimit");
	HookConVarChange(cvMpTimelimit, OnConVarChange);
	CreateConVar("is_bms_fix_timelimit_version", VERSION, "", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(!g_bBlocked){
	    	int iOldValue = StringToInt(oldValue);
	    	int iNewValue = StringToInt(newValue);
		int diff=iNewValue-iOldValue;

		changeTimelimit(diff);
	}
}

public changeTimelimit(diffTime){
	if(diffTime==0){
		return;
	}

	//create ent
	int entMpRoundTime = CreateEntityByName("mp_round_time");
	if (DispatchSpawn(entMpRoundTime)){

		//trigger input
		if(diffTime>0){
			SetVariantInt(diffTime);
			AcceptEntityInput(entMpRoundTime, "AddRoundTime"); 
		}else if(diffTime<0){
			diffTime=diffTime*-1;
			SetVariantInt(diffTime);
			AcceptEntityInput(entMpRoundTime, "RemoveRoundTime");
		}

		//byebye
		AcceptEntityInput(entMpRoundTime, "Kill"); 
	}
}

public OnMapStart(){
	g_bBlocked=false;
}
public OnMapEnd(){
	g_bBlocked=true;
}


//take the red pill
