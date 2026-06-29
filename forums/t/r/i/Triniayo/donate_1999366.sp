#pragma semicolon 1

#define PLUGIN_AUTHOR "Trinia"
#define PLUGIN_VERSION "1.5"

#include <sourcemod>

#pragma newdecls required

Handle g_paypalemail = null;
Handle g_currency = null;
Handle g_servername = null;
Handle g_mode = null;

public Plugin myinfo =
{
	name = "[ANY] PayPal Donations",
	author = PLUGIN_AUTHOR,
	description = "Simple plugin which allows players on the server to donate with PayPal through the MOTD window.",
	version = PLUGIN_VERSION,
	url = "http://Trinia.pro"
};

public void OnPluginStart() {
	//Version CVar
	CreateConVar("donate_version", PLUGIN_VERSION, "Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	//Plugin CVars
	g_paypalemail = CreateConVar("sm_paypal_email", "your-paypal@mail.com", "PayPal E-Mail Address \nEnter your PayPal E-Mail Address here.");
	g_currency = CreateConVar("sm_paypal_currency", "EUR", "PayPal Currency \nSet your Currency here. \nAll Currencies: EUR, USD, CHF.");
	g_servername = CreateConVar("sm_paypal_servername", "Servername", "This is the PayPal Payment Purpose. \nUse + instead of spaces \nExample: Server+Gaming+Network = Server Gaming Network \nLeave empty if player should choose itself.");
	g_mode = CreateConVar("sm_donate_command", "donate", "Donate Command \nChoose your command for the donations here.");
	AutoExecConfig(true, "plugin.donate");

	char Command[32];
	char buffer[32];
	GetConVarString(g_mode, Command, sizeof(Command));
	Format(buffer, sizeof(buffer), "sm_%s", Command);
	RegConsoleCmd(buffer, command_donate, "Donate URL");
}

public void OnConfigsExecuted() {
	char valid[100];
	GetConVarString(g_paypalemail, valid, sizeof(valid));
	if(!StrContains(valid, "@", true)) {
		SetFailState("Please enter a valid E-Mail Address.");
	}
}

public Action command_donate(int i, int args) {
	if (i > 0 && i < MaxClients && IsClientConnected(i) && IsClientInGame(i)) {
		if(args == 1) {
			char donateurl[192];
			char buffer[192];
			char amount[192];
			char currency[192];
			char servername[192];
			GetCmdArg(1, amount, sizeof(amount));
			GetConVarString(g_paypalemail, donateurl, sizeof(donateurl));
			GetConVarString(g_currency, currency, sizeof(currency));
			GetConVarString(g_servername, servername, sizeof(servername));
			if (StrEqual(servername, "")) {
				Format(buffer, sizeof(buffer), "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=%s&lc=US&amount=%s.00&currency_code=%s&no_note=0", donateurl, amount, currency);
			}
			else {
				Format(buffer, sizeof(buffer), "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=%s&item_name=%s&lc=US&amount=%s.00&currency_code=%s&no_note=0", donateurl, servername, amount, currency);
			}
			ShowMOTDPanel(i, "PayPal Donation", buffer, MOTDPANEL_TYPE_URL);
		}
		else {
			char Command[32];
			GetConVarString(g_mode, Command, sizeof(Command));
			PrintToChat(i, "\x01Usage: !%s <amount>",Command);
			PrintToConsole(i,"Usage: sm_%s <amount>",Command);
		}
	}
	return Plugin_Handled;
}
