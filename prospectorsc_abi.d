module prospectorsc_abi;
import transaction;

alias ID = uint64;
alias t_amount = int32;
alias t_balance = int64;
alias t_build = int16;
alias t_byte = uint8;
alias t_coord = int32;
alias t_energy = int16;
alias t_health = int32;
alias t_job = int16;
alias t_logo = uint32;
alias t_name = Name;
alias t_skill = int16;
alias t_type = int16;
alias t_utime = uint32;

struct AccountModel
{
	t_name name;
	uint32 flags;
	ID worker0;
	ID worker1;
	ID worker2;
	Purchase[] purchases;
	t_name referer;
	t_balance balance;
	t_balance referer_fee;
	t_name alliance;
	t_utime premium_time;
	uint32 points;
}

struct AllianceModel
{
	t_name name;
	t_name owner;
	t_utime cr_time;
	t_amount members;
	t_amount request;
	t_logo logo;
	uint64 r1;
	uint64 r2;
	uint64 r3;
	uint64 r4;
}

struct AuctionModel
{
	ID loc_id;
	t_byte type;
	t_name owner;
	t_name target;
	t_balance price;
	t_utime end_time;
	t_name bid_user;
	uint64 r1;
	uint64 r2;
}

struct Building
{
	t_build build_id;
	t_skill build_step;
	t_amount build_amount;
	t_utime ready_time;
	t_amount health;
	uint16 param;
	uint16 r1;
}

struct LocJob
{
	t_job job_type;
	t_job job_group;
	t_utime ready_time;
	t_name owner;
	Stuff stuff;
}

struct LocModel
{
	ID id;
	ID world_id;
	t_name owner;
	t_utime rent_time;
	string name;
	t_amount gold;
	t_amount wood;
	t_amount stone;
	t_amount coal;
	t_amount clay;
	t_amount ore;
	LocJob[] jobs;
	StorageStuff[] storage;
	Building building;
	t_amount coffee;
	t_amount[] resources;
	t_amount moss;
	uint16 flags;
	uint16 r2;
}

struct MarketModel
{
	ID id;
	ID loc_id;
	t_name owner;
	Stuff stuff;
	t_amount price;
	t_name alliance;
	uint64 r2;
}

struct OrderModel
{
	ID id;
	ID loc_id;
	t_name owner;
	t_job job_type;
	t_amount gold;
	t_amount amount;
	t_type item_id;
	t_amount item_prop;
	ID item_tag;
	int8 state;
	t_name alliance;
	t_byte is_stock;
	t_byte r2;
	uint16 r3;
	uint32 r4;
}

struct Purchase
{
	ID loc_id;
	Stuff stuff;
	t_amount reserved;
}

struct RailOrderModel
{
	ID id;
	t_name target;
	t_name owner;
	t_name recipient;
	Stuff stuff;
	t_amount price;
	t_amount gold;
	uint64 r1;
	uint64 r2;
}

struct RailStateModel
{
	t_name target;
	t_byte state;
	t_utime time;
	t_name last_index;
	t_balance total_weight;
	t_balance total_gold;
	t_amount orders_cnt;
	t_amount orders_done;
	uint64 r1;
	uint64 r2;
}

struct StatModel
{
	ID id;
	t_amount rent_price;
	t_utime begin_time;
	int32 job_count;
	int64 job_sum;
	uint64 r1;
	uint64 r2;
}

struct StorageModel
{
	ID loc_id;
	StorageStuff[] stuffs;
	LocJob[] jobs;
	uint64 r0;
}

struct StorageStuff
{
	t_type type_id;
	t_amount amount;
	t_health health;
	t_amount reserved;
}

struct Stuff
{
	t_type type_id;
	t_amount amount;
	t_health health;
}

struct WorkerJob
{
	t_job job_type;
	t_utime ready_time;
	Stuff stuff;
	uint8 is_backpack;
	ID loc_id;
	t_utime loc_time;
}

struct WorkerModel
{
	ID id;
	t_name owner;
	ID loc_id;
	ID prev_loc_id;
	WorkerJob job;
	Stuff[] backpack;
	Stuff[] equipment;
	string name;
	uint32 diplomas;
	t_energy energy;
	uint8 slots;
	uint8 r1;
	uint64 r2;
}

struct WorldModel
{
	ID id;
	int64 gold;
	int64 coal;
	int64 clay;
	int64 ore;
	uint64 seed;
	uint64 r2;
	uint64 r3;
	uint64 r4;
}

struct accptmember
{
	t_name account;
	t_name aname;
	t_name member;
}

struct arrestuser
{
	t_name account;
	t_amount days;
}

struct buycert
{
	t_name account;
	t_amount price;
}

struct buyenergy
{
	ID worker_id;
	t_amount rent_price;
}

struct buylicense
{
	t_name account;
	t_type stuff_id;
}

struct buywrkslot
{
	ID worker_id;
	t_amount price;
}

struct chrailord
{
	ID order_id;
	t_amount price;
}

struct chsale
{
	ID market_id;
	t_amount price;
}

struct distribtax
{
}

struct dobuild
{
	ID loc_id;
	ID worker_id;
	t_utime duration;
}

struct dodepart
{
	t_name target;
	t_amount count;
}

struct domake
{
	ID loc_id;
	ID worker_id;
	t_type type_id;
	t_amount amount;
}

struct domine
{
	ID loc_id;
	ID worker_id;
	t_type type_id;
	t_utime duration;
}

struct doorder
{
	ID order_id;
	ID worker_id;
	t_amount amount;
}

struct dorepair
{
	ID loc_id;
	ID worker_id;
	t_utime duration;
}

struct dosearch
{
	ID loc_id;
	ID worker_id;
	t_type type_id;
}

struct doself
{
	ID worker_id;
	t_type type_id;
	t_amount amount;
}

struct endauction
{
	ID loc_id;
}

struct endlocexpr
{
	ID loc_id;
}

struct endlocsale
{
	ID loc_id;
}

struct exitmember
{
	t_name account;
}

struct getdiploma
{
	ID worker_id;
	t_byte dip_id;
	t_amount price;
}

struct initstat
{
}

struct login
{
	t_name name;
	t_name referer;
}

struct mkalliance
{
	t_name account;
	t_name aname;
	t_logo logo;
	t_amount price;
}

struct mkauction
{
	ID loc_id;
	t_balance price;
}

struct mkbuild
{
	ID loc_id;
	t_build build_id;
}

struct mkbuildord
{
	ID loc_id;
	t_amount gold;
	t_utime duration;
	t_name alliance;
}

struct mkbuyord
{
	t_name account;
	ID loc_id;
	t_amount gold;
	t_type type_id;
	t_amount amount;
	t_name alliance;
}

struct mkcells
{
	ID world_id;
	t_coord min_x;
	t_coord min_y;
	t_coord max_x;
	t_coord max_y;
}

struct mkfreeloc
{
	ID loc_id;
}

struct mklocexpr
{
	ID loc_id;
	t_name account;
	t_amount price;
}

struct mklocsale
{
	ID loc_id;
	t_balance price;
	t_name target;
}

struct mkmakeord
{
	ID loc_id;
	t_amount gold;
	t_type type_id;
	t_amount amount;
	t_name alliance;
}

struct mkmineord
{
	ID loc_id;
	t_amount gold;
	t_type type_id;
	t_amount duration;
	t_name alliance;
}

struct mkpremium
{
	t_name account;
	t_amount days;
}

struct mkpremiumt
{
	t_name account;
}

struct mkpurchase
{
	t_name account;
	ID market_id;
	t_amount price;
	t_amount amount;
}

struct mkpurchord
{
	t_name account;
	ID loc_id;
	t_amount gold;
	Stuff stuff;
	ID dest_loc_id;
	t_name alliance;
}

struct mkrailord
{
	t_name account;
	t_name target;
	t_name recipient;
	Stuff stuff;
	t_amount price;
}

struct mkrepairord
{
	ID loc_id;
	t_amount gold;
	t_utime duration;
	t_name alliance;
}

struct mksale
{
	t_name account;
	ID loc_id;
	Stuff stuff;
	t_amount price;
	t_name alliance;
}

struct mktransord
{
	t_name account;
	ID loc_id;
	t_amount gold;
	Stuff stuff;
	ID dest_loc_id;
	t_name alliance;
}

struct mkworld
{
	ID id;
}

struct mvpurchstor
{
	t_name account;
	ID loc_id;
	Stuff stuff;
}

struct mvpurchwrk
{
	ID loc_id;
	ID worker_id;
	Stuff stuff;
	bool equip;
}

struct mvstorewrk
{
	ID loc_id;
	ID worker_id;
	Stuff stuff;
	bool equip;
}

struct mvstorgold
{
	ID loc_id;
	t_amount amount;
}

struct mvworker
{
	ID worker_id;
	t_coord x;
	t_coord y;
}

struct mvwrkgold
{
	ID worker_id;
	t_amount amount;
}

struct mvwrkstore
{
	ID loc_id;
	ID worker_id;
	Stuff stuff;
	bool equip;
}

struct mvwrkwrk
{
	ID from_worker_id;
	bool from_equip;
	ID to_worker_id;
	bool to_equip;
	Stuff stuff;
}

struct putlocbid
{
	ID loc_id;
	t_name account;
	t_amount price;
}

struct rentloc
{
	t_name account;
	ID loc_id;
	t_amount price;
	t_amount days;
}

struct reqmember
{
	t_name account;
	t_name aname;
}

struct retlicense
{
	ID worker_id;
	Stuff stuff;
}

struct rmauction
{
	ID loc_id;
}

struct rmbuild
{
	ID loc_id;
}

struct rmmember
{
	t_name account;
	t_name aname;
	t_name member;
}

struct rmorder
{
	ID order_id;
}

struct rmpurstuff
{
	t_name account;
	ID loc_id;
	Stuff stuff;
}

struct rmrailord
{
	ID order_id;
}

struct rmsale
{
	ID market_id;
}

struct rmstorstuff
{
	ID loc_id;
	Stuff stuff;
}

struct rmwrkstuff
{
	ID worker_id;
	Stuff stuff;
	bool equip;
}

struct rnloc
{
	ID loc_id;
	string name;
}

struct rnworker
{
	ID worker_id;
	string name;
}

struct seedloc
{
	ID loc_id;
	t_type stuff_id;
	t_amount amount;
}

struct sellstuff
{
	t_name account;
	ID order_id;
	t_amount amount;
}

struct setbankp
{
	ID loc_id;
	float32 percent;
}

struct setrole
{
	t_name account;
	t_name member;
	uint8 role;
}

struct takeoff
{
	ID worker_id;
	t_type type_id;
	t_health health;
}

struct takeon
{
	ID worker_id;
	t_type type_id;
	t_health health;
}

struct withdraw
{
	t_name account;
	t_amount amount;
}

alias accountElement = AccountModel;
alias allianceElement = AllianceModel;
alias auctionElement = AuctionModel;
alias locElement = LocModel;
alias marketElement = MarketModel;
alias orderElement = OrderModel;
alias raildepartElement = RailOrderModel;
alias railorderElement = RailOrderModel;
alias railstateElement = RailStateModel;
alias statElement = StatModel;
alias storageElement = StorageModel;
alias workerElement = WorkerModel;
alias worldElement = WorldModel;
