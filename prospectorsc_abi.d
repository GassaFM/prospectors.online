module prospectorsc_abi;
import transaction;

alias ID = uint64;
alias t_amount = int32;
alias t_balance = int64;
alias t_build = int16;
alias t_byte = uint8;
alias t_coord = int32;
alias t_health = int32;
alias t_job = int16;
alias t_name = Name;
alias t_skill = int16;
alias t_type = int16;
alias t_utime = uint32;

struct AccountModel
{
	Name name;
	uint32 flags;
	ID worker0;
	ID worker1;
	ID worker2;
	Purchase[] purchases;
	Name referer;
	t_balance balance;
	t_balance referer_fee;
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
	uint64 r1;
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
	Name owner;
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
	uint64 r2;
}

struct MarketModel
{
	ID id;
	ID loc_id;
	t_name owner;
	Stuff stuff;
	t_amount price;
	uint64 r1;
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
	uint64 r1;
	uint64 r2;
}

struct Purchase
{
	ID loc_id;
	Stuff stuff;
	t_amount reserved;
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
	Name owner;
	ID loc_id;
	ID prev_loc_id;
	WorkerJob job;
	Stuff[] backpack;
	Stuff[] equipment;
	string name;
	uint64 r1;
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

struct chsale
{
	ID market_id;
	t_amount price;
}

struct dobuild
{
	ID loc_id;
	ID worker_id;
	t_utime duration;
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

struct initstat
{
}

struct login
{
	t_name name;
	t_name referer;
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
}

struct mkbuyord
{
	ID loc_id;
	t_amount gold;
	t_type type_id;
	t_amount amount;
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
}

struct mkmineord
{
	ID loc_id;
	t_amount gold;
	t_type type_id;
	t_amount duration;
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
}

struct mksale
{
	ID loc_id;
	Stuff stuff;
	t_amount price;
}

struct mktransord
{
	ID loc_id;
	t_amount gold;
	Stuff stuff;
	ID dest_loc_id;
}

struct mkworld
{
	ID id;
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

struct rmauction
{
	ID loc_id;
}

struct rmbuild
{
	ID loc_id;
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
alias auctionElement = AuctionModel;
alias locElement = LocModel;
alias marketElement = MarketModel;
alias orderElement = OrderModel;
alias statElement = StatModel;
alias workerElement = WorkerModel;
alias worldElement = WorldModel;
