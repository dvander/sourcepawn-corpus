//시스템 시작
#include <sourcemod>
#include <sdktools>

//Item:
#define MAX_ITEMS 14+1
new Item[33][MAX_ITEMS];
new String:Item_Name[MAX_ITEMS][32];
new Item_Effect[MAX_ITEMS];
new Item_Class[MAX_ITEMS];
new Item_Weight[MAX_ITEMS];
new Item_[MAX_ITEMS];
new Item_Select[33][MAX_ITEMS];
new Item_Selection[33];
new Item_Start[33];
new Weapon[33];
new Shield[33];
new Engine[33];
new Body[33];
new Money[33];
new Weight[33];
new WeightW[33];
new WeightS[33];
new WeightE[33];
new WeightB[33];

//플러그인 시작
public OnPluginStart()
{
	LoadTranslations("newproject.phrases");
	RegConsoleCmd("say", Command_Say);

	//아이템(순서, 이름, 종류, 효과, 무게)
	CItem(1, "smg", 1, 0, 30);
	CItem(2, "shotgun", 1, 0, 40);
	CItem(3, "rpg", 1, 0, 60);
	CItem(4, "slam", 1, 0, 20);
	CItem(5, "Copper Shield", 2, 100, 40);
	CItem(6, "Iron Shield", 2, 300, 60);
	CItem(7, "Titaniun Shield", 2, 600, 80);
	CItem(8, "Nomar Engine", 3, 50, 40);
	CItem(9, "Fast Engine", 3, 80, 60);
	CItem(10, "Hi Fast Engine", 3, 100, 80);
	CItem(11, "Hi-End Engine", 3, 125, 100);
	CItem(12, "Buggy Car", 4, 50, 10);
	CItem(13, "Bike", 4, 10, 20);
	CItem(14, "Tank", 4, 200, 40);
}

public Action:Command_Say(Client, Arguments)
{

	//Slice and Dice:
	new String:Full_Text[255], String:Argument_Buffers[2][255], String:Quote_Character[1];
	GetCmdArgString(Full_Text, sizeof(Full_Text));

	//Get Quote Special Character:
	new Length = strlen(Full_Text);
	Quote_Character[0] = Full_Text[Length - 1];

	//Check:
	new bool:Alpha = IsCharAlpha(Quote_Character[0]);
	new bool:Numeric = IsCharNumeric(Quote_Character[0]);

	//Remove Quotes:
	if(!Alpha && !Numeric)
		ReplaceString(Full_Text, 255, Quote_Character[0], " "); 

	//Trim:
	TrimString(Full_Text);

	//Explode:
	ExplodeString(Full_Text, " ", Argument_Buffers, 2, 32);	

	//Cure
	if(StrEqual(Argument_Buffers[0], "!menu", false))	
	{
		Command_Menu(Client)
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

//Items:
public CItem(Item_ID, String:Temp_Item_Name[32], Temp_Item_Class, Temp_Item_Effect, Temp_Item_Weight)
{
	Item_Name[Item_ID] = Temp_Item_Name;
	Item_Class[Item_ID] = Temp_Item_Class;
	Item_Effect[Item_ID] = Temp_Item_Effect;
	Item_Weight[Item_ID] = Temp_Item_Weight;
}


//Items:
public Action:Command_Menu(Client)
{
	//출력:
	new Handle:Panel = CreatePanel();

	DrawPanelItem(Panel, "Equipment");
	DrawPanelItem(Panel, "Unequipment");
	DrawPanelItem(Panel, "Shop");

	SendPanelToClient(Panel, Client, Menu1, 30);

	//닫음
	CloseHandle(Panel);
}

//Panel Handle:
public Menu1(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	new Handle:Panel = CreatePanel();
	new Client = Parameter1;

	if (Click == MenuAction_Select)
	{

		if(Parameter2 == 1)
		{
			DrawPanelItem(Panel, "Weapon");
			DrawPanelItem(Panel, "Shield");
			DrawPanelItem(Panel, "Engine");
			DrawPanelItem(Panel, "Body");

			SendPanelToClient(Panel, Client, Menu_Equip, 30);
		}

		if(Parameter2 ==2)
		{

			DrawPanelItem(Panel, "Weapon");
			DrawPanelItem(Panel, "Shield");
			DrawPanelItem(Panel, "Engine");
			DrawPanelItem(Panel, "Body");

			SendPanelToClient(Panel, Client, Menu_Shop, 30);
		}
	}

	CloseHandle(Panel);
}

public Menu_Equip(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	new Handle:Panel = CreatePanel();
	new Client = Parameter1;

	if (Click == MenuAction_Select)
	{

		if(Parameter2 == 1)
		{
			DrawPanelItem(Panel, "SMG");
			DrawPanelItem(Panel, "Shotgun");
			DrawPanelItem(Panel, "RPG");
			DrawPanelItem(Panel, "SLAM");
			SendPanelToClient(Panel, Client, Menu_EquipW, 30);
		}

		if(Parameter2 == 2)
		{
			DrawPanelItem(Panel, "Copper Shield");
			DrawPanelItem(Panel, "Iron Shield");
			DrawPanelItem(Panel, "Titanium Shield");
			SendPanelToClient(Panel, Client, Menu_EquipS, 30);

		}

		if(Parameter2 == 3)
		{
			DrawPanelItem(Panel, "Nomar Engine");
			DrawPanelItem(Panel, "Fast Engine");
			DrawPanelItem(Panel, "Hi-Fast Engine");
			DrawPanelItem(Panel, "Hi-End Engine");
			SendPanelToClient(Panel, Client, Menu_EquipE, 30);
		}

		if(Parameter2 == 4)
		{
			DrawPanelItem(Panel, "Bike");
			DrawPanelItem(Panel, "Buggy Car");
			DrawPanelItem(Panel, "Tank");
			SendPanelToClient(Panel, Client, Menu_EquipB, 30);
		}
	}

	CloseHandle(Panel);
}

public Menu_Shop(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	new Handle:Panel = CreatePanel();
	new Client = Parameter1;

	if (Click == MenuAction_Select)
	{

		if(Parameter2 == 1)
		{
			DrawPanelItem(Panel, "SMG - 200$");
			DrawPanelItem(Panel, "Shotgun - 250$");
			DrawPanelItem(Panel, "RPG - 550");
			DrawPanelItem(Panel, "SLAM - 350$");

			SendPanelToClient(Panel, Client, Menu_ShopW, 30);
		}

		if(Parameter2 == 2)
		{
			DrawPanelItem(Panel, "Copper Shield - 200$");
			DrawPanelItem(Panel, "Iron Shield - 500$");
			DrawPanelItem(Panel, "Titanium Shield - 1200$");

			SendPanelToClient(Panel, Client, Menu_ShopS, 30);

		}

		if(Parameter2 == 3)
		{
			DrawPanelItem(Panel, "Nomar Engine - 200$");
			DrawPanelItem(Panel, "Fast Engine - 400$");
			DrawPanelItem(Panel, "Hi-Fast Engine - 800$");
			DrawPanelItem(Panel, "Hi-End Engine - 1600$");

			SendPanelToClient(Panel, Client, Menu_ShopE, 30);
		}

		if(Parameter2 == 4)
		{
			DrawPanelItem(Panel, "Bike - 100$");
			DrawPanelItem(Panel, "Buggy Car - 200$");
			DrawPanelItem(Panel, "Tank - 500$");

			SendPanelToClient(Panel, Client, Menu_ShopB, 30);
		}
	}

	CloseHandle(Panel);
}

public Menu_ShopW(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{

	//Click:
	if (Click == MenuAction_Select)
	{

		//Buy:
		if(Parameter2 == 1)
			Buy_Item(Parameter1, 200, 1);

		if(Parameter2 == 2)
			Buy_Item(Parameter1, 250, 2);

		if(Parameter2 == 3)
			Buy_Item(Parameter1, 550, 3);

		if(Parameter2 == 4)
			Buy_Item(Parameter1, 350, 4);

	}
}

public Menu_ShopS(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{

	//Click:
	if (Click == MenuAction_Select)
	{

		//Buy:
		if(Parameter2 == 1)
			Buy_Item(Parameter1, 200, 5);

		if(Parameter2 == 2)
			Buy_Item(Parameter1, 500, 6);

		if(Parameter2 == 3)
			Buy_Item(Parameter1, 1200, 7);

	}
}

public Menu_ShopE(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{

	//Click:
	if (Click == MenuAction_Select)
	{

		//Buy:
		if(Parameter2 == 1)
			Buy_Item(Parameter1, 200, 8);

		if(Parameter2 == 2)
			Buy_Item(Parameter1, 400, 9);

		if(Parameter2 == 3)
			Buy_Item(Parameter1, 800, 10);

		if(Parameter2 == 4)
			Buy_Item(Parameter1, 1600, 11);

	}
}

public Menu_ShopB(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{

	//Click:
	if (Click == MenuAction_Select)
	{

		//Buy:
		if(Parameter2 == 1)
			Buy_Item(Parameter1, 100, 12);

		if(Parameter2 == 2)
			Buy_Item(Parameter1, 200, 13);

		if(Parameter2 == 3)
			Buy_Item(Parameter1, 500, 14);

	}
}

public Menu_EquipW(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{

	//Click:
	if (Click == MenuAction_Select)
	{

		//Buy:
		if(Parameter2 == 1)
			Equip_ItemW(Parameter1, 30, 1);

		if(Parameter2 == 2)
			Equip_ItemW(Parameter1, 40, 2);

		if(Parameter2 == 3)
			Equip_ItemW(Parameter1, 60, 3);

		if(Parameter2 == 4)
			Equip_ItemW(Parameter1, 20, 4);

	}
}

public Menu_EquipS(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{

	//Click:
	if (Click == MenuAction_Select)
	{

		//Buy:
		if(Parameter2 == 1)
			Equip_ItemS(Parameter1, 40, 5);

		if(Parameter2 == 2)
			Equip_ItemS(Parameter1, 60, 6);

		if(Parameter2 == 3)
			Equip_ItemS(Parameter1, 80, 7);

	}
}

public Menu_EquipE(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{

	//Click:
	if (Click == MenuAction_Select)
	{

		//Buy:
		if(Parameter2 == 1)
			Equip_ItemE(Parameter1, 40, 8);

		if(Parameter2 == 2)
			Equip_ItemE(Parameter1, 60, 9);

		if(Parameter2 == 3)
			Equip_ItemE(Parameter1, 80, 10);

		if(Parameter2 == 4)
			Equip_ItemE(Parameter1, 100, 11);

	}
}

public Menu_EquipB(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{

	//Click:
	if (Click == MenuAction_Select)
	{

		//Buy:
		if(Parameter2 == 1)
			Equip_ItemB(Parameter1, 10, 12);

		if(Parameter2 == 2)
			Equip_ItemB(Parameter1, 20, 13);

		if(Parameter2 == 3)
			Equip_ItemB(Parameter1, 40, 14);

	}
}

public Buy_Item(Client, Cost, ItemID)
{

	//No Money:
	if(Money[Client] < Cost)
		PrintToChat(Client, "[nArGis] %t", "DontHaveMoney");
	else
	{

		//Exchange:
		Money[Client] = (Money[Client] - Cost);
		Item[Client][ItemID] += 1;

		//Print:
		PrintToChat(Client, "[nArGis] %t", "Purchase", Item_Name[ItemID]);
	}
}

public Equip_ItemW(Client, Weight, ItemID)
{
	new Item_ID = ItemID;

	if(Item_Class[Item_ID] = 1)
	{
		if(Item[Client][ItemID] < 1)
			PrintToChat(Client, "[nArGis] %t", "DontHave");
		else
		{
			if(Weight[Client] - WeightW[Client] + Weight > 200)
			{
				PrintToChat(Client, "[nArGis] %t", "TooWeight");
			}
			else
			{
				Weapon[Client] = ItemID;
				WeightW[Client] = Weight;
				Weight[Client] = (Weight[Client] + Weight);
			}
		}
	}
}

public Equip_ItemS(Client, Weight, ItemID)
{
	new Item_ID = ItemID;

	if(Item_Class[Item_ID] = 2)
	{
		if(Item_Name[ItemID] < 1)
			PrintToChat(Client, "[nArGis] %t", "DontHave");
		else
		{
			if(Weight[Client] - WeightW[Client] + Weight > 200)
			{
				PrintToChat(Client, "[nArGis] %t", "TooWeight");
			}
			else
			{
				Weapon[Client] = ItemID;
				WeightW[Client] = Weight;
				Weight[Client] = (Weight[Client] + Weight);
			}
		}
	}
}

public Equip_ItemE(Client, Weight, ItemID)
{
	new Item_ID = ItemID;

	if(Item_Class[Item_ID] = 3)
	{
		if(Item_Name[ItemID] < 1)
			PrintToChat(Client, "[nArGis] %t", "DontHave");
		else
		{
			if(Weight[Client] - WeightW[Client] + Weight > 200)
			{
				PrintToChat(Client, "[nArGis] %t", "TooWeight");
			}
			else
			{
				Weapon[Client] = ItemID;
				WeightW[Client] = Weight;
				Weight[Client] = (Weight[Client] + Weight);
			}
		}
	}
}

public Equip_ItemB(Client, Weight, ItemID)
{
	new Item_ID = ItemID;

	if(Item_Class[Item_ID] = 4)
	{
		if(Item_Name[ItemID] < 1)
			PrintToChat(Client, "[nArGis] %t", "DontHave");
		else
		{
			if(Weight[Client] - WeightW[Client] + Weight > 200)
			{
				PrintToChat(Client, "[nArGis] %t", "TooWeight");
			}
			else
			{
				Weapon[Client] = ItemID;
				WeightW[Client] = Weight;
				Weight[Client] = (Weight[Client] + Weight);
			}
		}
	}
}