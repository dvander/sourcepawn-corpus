//Khai Báo Cơ Sở Dữ Liệu Nguồn
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>

//Khai Báo Chung
#define PHIENBAN_PLUGIN  "1.0"

//Khai Báo Mảng Tên Bản Đồ
new String:BanDo1[13][150];
new String:BanDo2[13][150];	
new String:BanDo3[13][150];		
new String:BanDo4[13][150];
new String:BanDo5[13][150];

//Khai Báo Biến Xác Nhận
new bool:XacNhanTrongSafe=false;
new bool:XacNhanRoiSafe=false;

//Cài Đặt Map
SetupMap()
{
	//Bản Đồ Đầu Tiên
	Format(BanDo1[0], 150, "c1m1_hotel");	
	Format(BanDo1[1], 150, "c2m1_highway");	
	Format(BanDo1[2], 150, "c3m1_plankcountry");	
	Format(BanDo1[3], 150, "c4m1_milltown_a");
	Format(BanDo1[4], 150, "c5m1_waterfront");
	Format(BanDo1[5], 150, "c6m1_riverbank");
	Format(BanDo1[6], 150, "c7m1_docks");
	Format(BanDo1[7], 150, "c8m1_apartment");
	Format(BanDo1[8], 150, "c9m1_alleys");
	Format(BanDo1[9], 150, "c10m1_caves");
	Format(BanDo1[10], 150, "c11m1_greenhouse");
	Format(BanDo1[11], 150, "c12m1_hilltop");
	Format(BanDo1[12], 150, "c13m1_alpinecreek");
	
	//Bản Đồ Thứ Hai
	Format(BanDo2[0], 150, "c1m2_streets");	
	Format(BanDo2[1], 150, "c2m2_fairgrounds");	
	Format(BanDo2[2], 150, "c3m2_swamp");	
	Format(BanDo2[3], 150, "c4m2_sugarmill_a");
	Format(BanDo2[4], 150, "c5m2_park");
	Format(BanDo2[5], 150, "c6m2_bedlam");
	Format(BanDo2[6], 150, "c7m2_barge");
	Format(BanDo2[7], 150, "c8m2_subway");
	Format(BanDo2[8], 150, "c9m2_lots");
	Format(BanDo2[9], 150, "c10m2_drainage");
	Format(BanDo2[10], 150, "c11m2_offices");
	Format(BanDo2[11], 150, "C12m2_traintunnel");
	Format(BanDo2[12], 150, "c13m2_southpinestream");
	
	//Bản Đồ Đầu Ba
	Format(BanDo3[0], 150, "c1m3_mall");	
	Format(BanDo3[1], 150, "c2m3_coaster");	
	Format(BanDo3[2], 150, "c3m3_shantytown");	
	Format(BanDo3[3], 150, "c4m3_sugarmill_b");
	Format(BanDo3[4], 150, "c5m3_cemetery");
	Format(BanDo3[5], 150, "c6m3_port");
	Format(BanDo3[6], 150, "c7m3_port");
	Format(BanDo3[7], 150, "c8m3_sewers");
	Format(BanDo3[8], 150, "");
	Format(BanDo3[9], 150, "c10m3_ranchhouse");
	Format(BanDo3[10], 150, "c11m3_garage");
	Format(BanDo3[11], 150, "C12m3_bridge");
	Format(BanDo3[12], 150, "c13m3_memorialbridge");
	
	//Bản Đồ Thứ Tư
	Format(BanDo4[0], 150, "c1m4_atrium");	
	Format(BanDo4[1], 150, "c2m4_barns");	
	Format(BanDo4[2], 150, "c3m4_plantation");	
	Format(BanDo4[3], 150, "c4m4_milltown_b");
	Format(BanDo4[4], 150, "c5m4_quarter");
	Format(BanDo4[5], 150, "");
	Format(BanDo4[6], 150, "");
	Format(BanDo4[7], 150, "c8m4_interior");
	Format(BanDo4[8], 150, "");
	Format(BanDo4[9], 150, "c10m4_mainstreet");
	Format(BanDo4[10], 150, "c11m4_terminal");
	Format(BanDo4[11], 150, "C12m4_barn");
	Format(BanDo4[12], 150, "c13m4_cutthroatcreek");
	
	//Bản Đồ Thứ Năm
	Format(BanDo5[0], 150, "");	
	Format(BanDo5[1], 150, "c2m5_concert");	
	Format(BanDo5[2], 150, "");
	Format(BanDo5[3], 150, "c4m5_milltown_escape");	
	Format(BanDo5[4], 150, "c5m5_bridge");
	Format(BanDo5[5], 150, "");
	Format(BanDo5[6], 150, "");
	Format(BanDo5[7], 150, "c8m5_rooftop");
	Format(BanDo5[8], 150, "");
	Format(BanDo5[9], 150, "c10m5_houseboat");
	Format(BanDo5[10], 150, "c11m5_runway");
	Format(BanDo5[11], 150, "c12m5_cornfield");
	Format(BanDo5[12], 150, "");

}

/*======================================================================================
                                INFORMATION P L U G I N S                                
======================================================================================*/
public Plugin:ThongTinPlugin =
{
    name = "Back First Map When Campaign Fails",
    author = "manhkst - Nguyễn Thành Mẫn",
    description = "If the campaign fails at any map then will back first map of chapter",
    version = PHIENBAN_PLUGIN,
    url = "http://www.fleeingdeath.blogspot.com"
}
/*======================================================================================
                                Kiểm Tra Game Left 4 Dead 2                               
======================================================================================*/
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
/*======================================================================================
                                 P L U G I N S  Bắt Đầu                            
======================================================================================*/
public OnPluginStart()
{
	SetupMap();
	HookEvent("mission_lost", Event_Thua);
	HookEvent("player_left_start_area",Event_RoiKhoiSafe);
	HookEvent("player_entered_start_area",Event_TrongSafe);	
	HookEvent("round_start", Event_BatDau);
}
/*======================================================================================
                                 E V E N T S                            
======================================================================================*/
public Action:Event_TrongSafe(Handle:event, const String:name[], bool:dontBroadcast)
{
	XacNhanTrongSafe=true;
}
public Action:Event_BatDau(Handle:event, const String:name[], bool:dontBroadcast)
{
	XacNhanTrongSafe=true;
	XacNhanRoiSafe=true;
}
public Action:Event_RoiKhoiSafe(Handle:event, const String:name[], bool:dontBroadcast)
{
	XacNhanRoiSafe=true;
}
public Action:Event_Thua(Handle:event, String:event_name[], bool:dontBroadcast)
{	
	//Khởi Tạo Biến Chế Độ
	decl String:strGameMode[20];
	GetConVarString(FindConVar("mp_gamemode"), strGameMode, sizeof(strGameMode));
	if(StrEqual(strGameMode, "coop") || StrEqual(strGameMode, "realism")) //Kiểm Tra Chế Độ Game Đang Chơi
	{
		if(XacNhanRoiSafe==true && XacNhanTrongSafe==true)
		{
			decl String:strTenBanDo[150];
			GetCurrentMap(strTenBanDo,150);	//Bản Đồ Hiện Tại Từ Trò Chơi
			for(new iSoBanDoHienTai = 0; iSoBanDoHienTai < 13; iSoBanDoHienTai++)
			{		
				if((StrEqual(strTenBanDo, BanDo2[iSoBanDoHienTai]) == true) || (StrEqual(strTenBanDo, BanDo3[iSoBanDoHienTai]) == true) || (StrEqual(strTenBanDo, BanDo4[iSoBanDoHienTai]) == true) || (StrEqual(strTenBanDo, BanDo5[iSoBanDoHienTai]) == true)) 
				{			
					CreateTimer(2.5, HamChuyenBanDoKeTiep, iSoBanDoHienTai);
					PrintToChatAll("\x04[\x05FD ʚïɞ Team\x04] \x02Campaign Fails! Back First Map Of Chapter");
					XacNhanTrongSafe=false;
					XacNhanRoiSafe=false;
				}
			}
		}
	}
}
/*======================================================================================
                                 F U N C T I O N                            
======================================================================================*/
public Action:HamChuyenBanDoKeTiep(Handle:timer, any:BanDoChuyen)
{
	ServerCommand("changelevel %s", BanDo1[BanDoChuyen]); //Chuyển Bản Đồ
	
	return Plugin_Stop;
}