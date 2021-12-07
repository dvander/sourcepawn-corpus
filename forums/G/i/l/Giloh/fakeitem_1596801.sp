#include <sourcemod>
#define VERSION "1.0"
#define itemListSize 111

new String:itemList[itemListSize][25] = { "Bat", "Bottle", "Axe", "Kukri", "Knife", "Fists", "Shovel", "Wrench", "Bonesaw", "Shotgun",
"Shotgun", "Shotgun", "Shotgun", "Scattergun", "Rifle", "Minigun", "SMG", "Syringe", "Rocket-Launcher", "Grenade-Launcher",
"Sticky-Launcher", "Flamethrower", "Pistol", "Pistol", "Revolver", "PDA", "PDA", "PDA", "PDA", "Medi-Gun",
"Invis-Watch", "31", "32", "33", "34", "Kritzkrieg", "Blutsauger", "Ubersaw", "Axtinguisher", "Flaregun",
"Backburner", "Natascha", "Sandvich", "Killing-Gloves-Of-Boxing", "Sandman", "Force-a-Nature", "Bonk", "Demo-Fro", "Mining-Light", "Football-Helmet",
"Prussian", "Pyro-Beanie", "Batter-Helmet", "Trophy-Belt", "Soldier-Stash", "Fancy-Fedora", "Huntsman", "Razorback", "Jarate", "Dead-Ringer",
"Cloak-and-Dagger", "Ambassador", "62", "63", "64", "65", "66", "67", "68", "69",
"70", "71", "72", "73", "74", "75", "76", "77", "78", "79",
"80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
"90", "91", "92", "93", "Texas-Ten-Gallon", "Engineer-Cup", "Officers-Ushanka", "Tough-Guy-Toque", "Stainless-Pot", "Tyrant-Helm",
"Glenbarry-Bonnet", "Vintage-Tyrolean", "Respectless-Rubber-Glove", "Camera-Beard", "Medic-Mirror ", "Brigade-Helm", "Bonk-Helm", "Ye-Olde-Baker-Boy", "Backbiter-Billycock", "Professional-Panama",
"Yellow-Belt" }

public Plugin:myinfo = {
	name = "FakeItem events",
	author = "Giloh",
	description = "",
	version = VERSION,
	url = "null"
};

public OnPluginStart(){
	CreateConVar("sm_fakeitem_version", VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_fakeitem", Command_FakeItem, ADMFLAG_GENERIC, "For more info: sm_fakeitem help");
}

FakeItem_ItemSort(client, String:sItem[]){
	StripQuotes(sItem);
	if(!StrEqual(sItem, "0") && StringToInt(sItem) == 0){
		new bool:bLoop = false;
		for(new i = 0; i < itemListSize; i++){
			if(!bLoop){
				if(StrEqual(sItem, itemList[i], false)){
					return i;
				}
			}
		}
		if(!bLoop){
			ReplyToCommand(client, "\x04[SM] \x01Item not in list. Try: sm_fakeitem names");
			return -1;
		}
	} else if(StringToInt(sItem) >= 0 && StringToInt(sItem) <= 528){
			return StringToInt(sItem);
	} else {
		ReplyToCommand(client, "\x04[SM] \x01Invalid Item Index");
		return -1;
	}
	return -1;
}

public Action:Command_FakeItem(client, args){
	if(GetCmdArgs() == 1){
		new String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));
		if(StrEqual(arg, "help")){
			PrintToConsole(client, "\n-----FAKE ITEMS-----");
			ReplyToCommand(client, "sm_fakeitem <item>");
			PrintToConsole(client, "sm_fakeitem <method> <quality> <item>");
			PrintToConsole(client, "sm_fakeitem help - Prints this");
			PrintToConsole(client, "sm_fakeitem names - Prints a list of names that can be used in the <item> argument");
			PrintToConsole(client, "\nValid Method Arguments:\n 0 - find\n 1 - craft\n 2 - trade\n 3 - buy\n 4 - unbox\n 5 - gift\n 8 - earn\n 9 - refund\n 10 - wrap");
			PrintToConsole(client, "\nValid Quality Arguments:\n 0 - normal\n 1 - genuine\n 2 - color1\n 3 - vintage\n 4 - color2\n 5 - unusual\n 6 - unique\n 7 - community\n 8 - valve\n 9 - selfmade\n 10 - custom\n 11 - strange\n 12 - complete\n 13 - haunted");
			PrintToConsole(client, "\nValid Item Arguments:\n Indexes from: http://wiki.amxmodx.org/Team_Fortress_2_Item_Definition_Indexes\n Names from: sm_fakeitem names");
			PrintToConsole(client, "-----FAKE ITEMS-----\n");
			PrintToChat(client, "\x04[SM] \x01Check console for output");
		} else if(StrEqual(arg, "names")){
			PrintToConsole(client, "\n-----FAKE ITEMS-----");
			PrintToConsole(client, "Accepted Names:");
			for(new i = 0; i < itemListSize; i++){
				PrintToConsole(client, " %d - %s", i, itemList[i]);
			}
			PrintToConsole(client, " (not case sensitive)");
			PrintToConsole(client, "-----FAKE ITEMS-----\n");
			PrintToChat(client, "\x04[SM] \x01Check console for output");
		} else {
			new String:sItem[32];
			GetCmdArg(1, sItem, sizeof(sItem));
			new item = FakeItem_ItemSort(client, sItem);
			if(item == -1) return Plugin_Handled;
			
			new Handle:event = CreateEvent("item_found");
			if(event == INVALID_HANDLE){
				return Plugin_Handled;
			}
			SetEventInt(event, "player", client);
			SetEventInt(event, "method", 0);
			SetEventInt(event, "quality", 0);
			SetEventInt(event, "itemdef", item);
			SetEventBool(event, "isfake", true);
			FireEvent(event, false);
			ShowActivity2(client, "[SM]", "%N triggered FakeItem method:0 quality:0 index:%d", client, item);
		}
		return Plugin_Handled;
	}
	
	if(args != 1 && args != 3){
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_fakeitem <item>");
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_fakeitem <method> <quality> <item>");
		ReplyToCommand(client, "\x04[SM] \x01For help: sm_fakeitem help");
		ReplyToCommand(client, "\x04[SM] \x01For names: sm_fakeitem names");
		return Plugin_Handled;
	}
	
	new String:sItem[32], String:sMethod[8], String:sQuality[8];
	new method, quality, item;
	method = quality = item = 0;
	GetCmdArg(1, sMethod, sizeof(sMethod));
	GetCmdArg(2, sQuality, sizeof(sQuality));
	GetCmdArg(3, sItem, sizeof(sItem));
	
	StripQuotes(sMethod);
	if (StringToInt(sMethod) == 0 && !StrEqual(sMethod, "0")){
		if(StrEqual(sMethod, "craft", false) || StrEqual(sMethod, "crafted", false)){
			method = 1;
		} else if(StrEqual(sMethod, "trade", false) || StrEqual(sMethod, "traded", false)){
			method = 2;
		} else if(StrEqual(sMethod, "buy", false) || StrEqual(sMethod, "bought", false)){
			method = 3;
		} else if(StrEqual(sMethod, "unbox", false) || StrEqual(sMethod, "uncrate", false) || StrEqual(sMethod, "unboxed", false)){
			method = 4;
		} else if(StrEqual(sMethod, "gift", false) || StrEqual(sMethod, "gifted", false)){
			method = 5;
		} else if(StrEqual(sMethod, "earn", false) || StrEqual(sMethod, "earned", false)){
			method = 8;
		} else if(StrEqual(sMethod, "refund", false) || StrEqual(sMethod, "refunded", false)){
			method = 9;
		} else if(StrEqual(sMethod, "wrap", false) || StrEqual(sMethod, "wrapped", false)){
			method = 10;
		} else if(!StrEqual(sMethod, "find", false) && !StrEqual(sMethod, "found", false)){
			ReplyToCommand(client, "\x04[SM] \x01Invalid Method Argument");
			return Plugin_Handled;
		}
	} else if(StringToInt(sMethod) >= 0 && StringToInt(sMethod) <= 10){
		method = StringToInt(sMethod);
		if(method == 6 || method == 7){
			ReplyToCommand(client, "6 and 7 aren't valid methods");
			return Plugin_Handled;
		}
	} else {
		ReplyToCommand(client, "\x04[SM] \x01Invalid Method Value");
		return Plugin_Handled;
	}

	StripQuotes(sQuality);	
	if (StringToInt(sQuality) == 0 && !StrEqual(sQuality, "0")){
		if(StrEqual(sQuality, "genuine", false)){
			quality = 1;
		} else if(StrEqual(sQuality, "color1", false)){
			quality = 2;
		} else if(StrEqual(sQuality, "vintage", false)){
			quality = 3;
		} else if(StrEqual(sQuality, "color2", false)){
			quality = 4;
		} else if(StrEqual(sQuality, "unusual", false)){
			quality = 5;
		} else if(StrEqual(sQuality, "unique", false)){
			quality = 6;
		} else if(StrEqual(sQuality, "community", false)){
			quality = 7;
		} else if(StrEqual(sQuality, "valve", false)){
			quality = 8;
		} else if(StrEqual(sQuality, "selfmade", false) || StrEqual(sQuality, "self-made", false)){
			quality = 9;
		} else if(StrEqual(sQuality, "custom", false) || StrEqual(sQuality, "customized", false)){
			quality = 10;
		} else if(StrEqual(sQuality, "strange", false)){
			quality = 11;
		} else if(StrEqual(sQuality, "complete", false) || StrEqual(sQuality, "completed", false)){
			quality = 12;
		} else if(StrEqual(sQuality, "haunted", false)){
			quality = 13;
		} else if(!StrEqual(sQuality, "normal")){
			ReplyToCommand(client, "\x04[SM] \x01Invalid Quality Argument");
			return Plugin_Handled;
		}
	} else if(StringToInt(sQuality) >= 0 && StringToInt(sQuality) <= 13){
		quality = StringToInt(sQuality);
	} else {
		ReplyToCommand(client, "\x04[SM] \x01Invalid Quality Value");
		return Plugin_Handled;
	}
	
	item = FakeItem_ItemSort(client, sItem);
	if(item == -1) return Plugin_Handled;
	
	new Handle:event = CreateEvent("item_found");
	if(event == INVALID_HANDLE){
		return Plugin_Handled;
	}
	SetEventInt(event, "player", client);
	SetEventInt(event, "method", method);
	SetEventInt(event, "quality", quality);
	SetEventInt(event, "itemdef", item);
	SetEventBool(event, "isfake", true);
	FireEvent(event, false);
	
	ShowActivity2(client, "[SM]", "%N triggered FakeItem method:%d quality:%d index:%d", client, method, quality, item);
	return Plugin_Handled;
}