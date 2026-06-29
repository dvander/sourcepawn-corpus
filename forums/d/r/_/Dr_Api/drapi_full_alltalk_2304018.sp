/*       <DR.API FULL ALLTALK> (c) by <De Battista Clint - (http://doyou.watch)      */
/*                                                                           */
/*                      <DR.API BASE> is licensed under a                    */
/* Creative Commons Attribution-NonCommercial-NoDerivs 4.0 Unported License. */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*  work.  If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.  */
//***************************************************************************//
//***************************************************************************//
//********************************DR.API FULL ALLTALK********************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API FULL ALLTALK",
	author = "Dr. Api",
	description = "DR.API FULL ALLTALK by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	SetConVarInt(FindConVar("sv_full_alltalk"), 1, false, false);
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	SetConVarInt(FindConVar("sv_full_alltalk"), 1, false, false);
}