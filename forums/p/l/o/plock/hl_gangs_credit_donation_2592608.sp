/*  [CS:GO] hl_gangs - credits donation
 *
 *  Copyright (C) 2018 Daniel Sartor // kniv.com.br // plock@kniv.com.br
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdkhooks>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <store>
#include <hl_gangs_credits>
#include <myjailshop>
#include <shop>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define PLUGIN_AUTHOR "Plock, Headline"
#define PLUGIN_VERSION "1.2"

ConVar g_ConVar_MinAmount;
ConVar g_ConVar_MaxAmount;
ConVar g_ConVar_CreditFee;
ConVar g_ConVar_FeeSubstract;

/* Supported Store Modules */
bool g_bZepyhrus = false;
bool g_bShanapu = false;
bool g_bDefault = false;
bool g_bFrozdark = false;

public Plugin myinfo = {
    name = "Gangs - Credits Donation",
    author = PLUGIN_AUTHOR,
    version = PLUGIN_VERSION,
    url = "www.kniv.com.br"
};

public void OnPluginStart() {
	
	AutoExecConfig_SetFile("hl_gangs_credits_donation");
	AutoExecConfig_SetCreateFile(true);
	g_ConVar_MinAmount = AutoExecConfig_CreateConVar("credits_donation_min_amount", "0", "Minimum amount of credits to be donated.", FCVAR_NONE);
	g_ConVar_MaxAmount = AutoExecConfig_CreateConVar("credits_donation_max_amount", "0", "0 = Unlimited. Any other value is the maximum amount of credits to be donated.", FCVAR_NONE);
	g_ConVar_CreditFee = AutoExecConfig_CreateConVar("credits_donation_fee", "0.0", "Amount of fee that will be taken from the donation. 0.0 = No Fee, 0.1 = 10% of the donated value will be taken.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_ConVar_FeeSubstract = AutoExecConfig_CreateConVar("credits_donation_fee_subtract", "1", "1 = Receiver pay the fee. 0 = Sender pay the fee (if he send 1000 and fee is 10%, he needs to have 1100 credits).", FCVAR_NONE);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	RegConsoleCmd("sm_donatecredits", Command_DonateCredits);
	
	LoadTranslations("hl_gangs_credits_donation.phrases");
	
	g_bZepyhrus = LibraryExists("store_zephyrus");
	if (g_bZepyhrus)
	{
		return; // Don't bother checking if others exist
	}

	g_bShanapu = LibraryExists("myjailshop");
	if (g_bShanapu)
	{
		return; // Don't bother checking if others exist
	}

	g_bFrozdark = LibraryExists("shop");
	if (g_bFrozdark)
	{
		return; // Don't bother checking if others exist
	}
	
	/* Stores */
	g_bDefault = LibraryExists("hl_gangs_credits");
	if (g_bDefault)
	{
		return; // Don't bother checking if others exist
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "store_zephyrus"))
	{
		g_bZepyhrus = true;
	}
	else if (StrEqual(name, "myjailshop"))
	{
		g_bShanapu = true;
	}
	else if (StrEqual(name, "shop"))
	{
		g_bFrozdark = true;
	}
	else if (StrEqual(name, "hl_gangs_credits"))
	{
		g_bDefault = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "store_zephyrus"))
	{
		g_bZepyhrus = false;
	}
	else if (StrEqual(name, "myjailshop"))
	{
		g_bShanapu = false;
	}
	else if (StrEqual(name, "shop"))
	{
		g_bFrozdark = false;
	}
	else if (StrEqual(name, "hl_gangs_credits"))
	{
		g_bDefault = false;
	}
}

public Action Command_DonateCredits(int client, int args) {
	if(args != 2) {
		ReplyToCommand(client, "Usage: sm_donatecredits <name | #userid> <amount>");
		return Plugin_Handled;
	}

	char sArg[256];
	char sTempArg[32];
	char sAmount[15];
	int iL;
	int iNL;
	
	GetCmdArgString(sArg, sizeof(sArg));
	iL = BreakString(sArg, sTempArg, sizeof(sTempArg));
	
	if((iNL = BreakString(sArg[iL], sAmount, sizeof(sAmount))) != -1)
		iL += iNL;
	
	int iTarget = FindTarget(client, sTempArg, true, false); 
	
	if(iTarget != -1 && !IsFakeClient(iTarget) && IsValidClient(iTarget)) {
		int amount;
		amount = StringToInt(sAmount);

		if (amount < g_ConVar_MinAmount.IntValue) {
			PrintToChat(client, "%T","Min Amount Required", client, g_ConVar_MinAmount.IntValue);
			return Plugin_Handled;
		}
		
		if (g_ConVar_MaxAmount.IntValue > 0 && amount > g_ConVar_MaxAmount.IntValue) {
			PrintToChat(client, "%T","Max Amount Required", client, g_ConVar_MaxAmount.IntValue);
			return Plugin_Handled;
		}
		
		int fee = 0;
		if (g_ConVar_CreditFee.FloatValue > 0.0) {
			fee = RoundToNearest(amount * g_ConVar_CreditFee.FloatValue);
		}
		
		int totalAmount = amount;
		if (g_ConVar_FeeSubstract.IntValue == 0) {
			totalAmount += fee;
		}
			
		int currentCredits = GetClientCredits(client);
		if (currentCredits < totalAmount) {
			PrintToChat(client, "%T", "Not enough Credits", client);
			return Plugin_Handled;
		}
		
		int receivedValue = totalAmount - fee;
		PrintToChat(client, "%T","Donated Credits", client, receivedValue, iTarget);
		PrintToChat(iTarget, "%T","Received Credits", iTarget, client,receivedValue);
		SetClientCredits(client, GetClientCredits(client) - totalAmount);
		SetClientCredits(iTarget, GetClientCredits(iTarget) + receivedValue);
		
		return Plugin_Continue;	
	} else {
		PrintToChat(client, "%T", "Player not found", client);
		return Plugin_Handled;
	}
}

int GetClientCredits(int client)
{
	if (g_bZepyhrus)
	{
		return Store_GetClientCredits(client);
	}
	else if (g_bShanapu)
	{
		return MyJailShop_GetCredits(client);
	}
	else if (g_bFrozdark)
	{
		return Shop_GetClientCredits(client);
	}
	else if (g_bDefault)
	{
		return Gangs_GetCredits(client);
	}
	else
	{
		SetFailState("ERROR: No supported credits plugin loaded!");
		return 0;
	}
}

void SetClientCredits(int client, int iAmmount)
{
	if (g_bZepyhrus)
	{
		Store_SetClientCredits(client, iAmmount);
	}
	else if (g_bShanapu)
	{
		MyJailShop_SetCredits(client, iAmmount);
	}
	else if (g_bFrozdark)
	{
		Shop_SetClientCredits(client, iAmmount);
	}
	else if (g_bDefault)
	{
		Gangs_SetCredits(client, iAmmount);
	}
	else
	{
		SetFailState("ERROR: No supported credits plugin loaded!");
	}
}


stock bool IsValidClient(int client) { 
	if (!( 1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	if (IsFakeClient(client))
		return false;
	return true; 
}