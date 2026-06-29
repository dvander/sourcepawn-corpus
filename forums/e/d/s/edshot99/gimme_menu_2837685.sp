/*
 * gimme_menu.sp
 * Copyright (c) 2025 Ed <ed@groovyexpress.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sourcemod>
#include <tf_econ_data>

public Plugin myinfo =
{
	name = "[TF2] Gimme Menu",
	author = "EDSHOT",
	description = "Give yourself items easily",
	version = "0.1"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_items", itemMenu);
}

public Action itemMenu(int client, int args)
{
	Handle hItemMenu = CreateMenu(itemMenuHandler);
	SetMenuTitle(hItemMenu, "Gimme Menu");

	AddMenuItem(hItemMenu, "option0", "Primary");
	AddMenuItem(hItemMenu, "option1", "Secondary");
	AddMenuItem(hItemMenu, "option2", "Melee");
	AddMenuItem(hItemMenu, "option3", "Reset All Items");

	SetMenuExitButton(hItemMenu, true);
	DisplayMenu(hItemMenu, client, 20);

	return Plugin_Handled;
}

public itemMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 3)
		{
			ClientCommand(param1, "%s", "sm_resetp");
		}
		else
		{
			itemListMenu(param1, param2);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action itemListMenu(int client, int args)
{
	Handle hItemListMenu = CreateMenu(itemListMenuHandler);

	char itemListMenuTitle[64];
	ArrayList itemList;
	if (args == 0)
	{
		itemListMenuTitle = "Gimme Menu - Primary Weapons";
		itemList = TF2Econ_GetItemList(FilterClassPrimary, TF2_GetPlayerClass(client));
	}
	else if (args == 1)
	{
		itemListMenuTitle = "Gimme Menu - Secondary Weapons";
		itemList = TF2Econ_GetItemList(FilterClassSecondary, TF2_GetPlayerClass(client));
	}
	else if (args == 2)
	{
		itemListMenuTitle = "Gimme Menu - Melee Weapons";
		itemList = TF2Econ_GetItemList(FilterClassMelee, TF2_GetPlayerClass(client));
	}
	SetMenuTitle(hItemListMenu, itemListMenuTitle);

	char itemIndexStr[16];
	char itemName[64];
	for (int i = 0; i < itemList.Length; i++)
	{
		int itemIndex = itemList.Get(i);
		IntToString(itemIndex, itemIndexStr, sizeof(itemIndexStr));

		TF2Econ_GetItemName(itemIndex, itemName, sizeof(itemName));
		Format(itemName, sizeof(itemName), "%s (%i)", itemName, itemIndex);

		AddMenuItem(hItemListMenu, itemIndexStr, itemName);
	}

	SetMenuExitButton(hItemListMenu, true);
	DisplayMenu(hItemListMenu, client, 20);

	delete(itemList);

	return Plugin_Handled;
}

public itemListMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char itemIndexStr[16];
		GetMenuItem(menu, param2, itemIndexStr, sizeof(itemIndexStr));

		int itemIndex = StringToInt(itemIndexStr);
		ClientCommand(param1, "%s %i", "sm_gimmep", itemIndex);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public bool FilterClassPrimary(int itemdef, TFClassType playerClass)
{
	return (TF2Econ_GetItemLoadoutSlot(itemdef, playerClass) == TF2Econ_TranslateLoadoutSlotNameToIndex("primary"));
}

public bool FilterClassSecondary(int itemdef, TFClassType playerClass)
{
	return (TF2Econ_GetItemLoadoutSlot(itemdef, playerClass) == TF2Econ_TranslateLoadoutSlotNameToIndex("secondary"));
}

public bool FilterClassMelee(int itemdef, TFClassType playerClass)
{
	return (TF2Econ_GetItemLoadoutSlot(itemdef, playerClass) == TF2Econ_TranslateLoadoutSlotNameToIndex("melee"));
}
