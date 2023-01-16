use ipl;

# 1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage.

with t as(
select BIDDER_ID, count(*) win_cnt from ipl_bidding_details where BID_STATUS = 'won' group by BIDDER_ID
)
select BIDDER_ID, ifnull(win_cnt,0) win_cnt1,count(*) bid_cnt, round((ifnull(win_cnt,0)/count(*))*100,2) Win_pct 
from ipl_bidding_details left join t using (bidder_id) group by BIDDER_ID, win_cnt1
order by win_pct desc;


# 2.	Display the number of matches conducted at each stadium with the stadium name and city.

select Stadium_name, city, count(*) Match_cnt 
from ipl_match_schedule join ipl_stadium using (stadium_id) 
where STATUS != 'cancelled'
group by STADIUM_ID;

# 3.	In a given stadium, what is the percentage of wins by a team which has won the toss?

with temp as (
select STADIUM_ID, count(*) ww_cnt from ipl_match 
join ipl_match_schedule using (match_id) 
where TOSS_WINNER = MATCH_WINNER group by STADIUM_ID
)
select STADIUM_ID, ww_cnt, count(*) Match_cnt, round(ww_cnt*100/count(*),2) toss_and_match_win_pct
from ipl_match_schedule join temp using (stadium_id) 
where STATUS = 'Completed'
group by STADIUM_ID 
order by stadium_id
;

# 4.	Show the total bids along with the bid team and team name.

select BID_TEAM, TEAM_NAME, count(*) total_bids 
from ipl_bidding_details 
join ipl_team on BID_TEAM = TEAM_ID 
group by BID_TEAM order by bid_team;

# 5.	Show the team id who won the match as per the win details.

select match_id,WIN_DETAILS, 
(select team_id from ipl_team b where a.win_details like concat('%',b.remarks,'%')) team_id 
from ipl_match a;

# 6.	Display total matches played, total matches won and total matches lost by the team along with its team name.

select TEAM_NAME, sum(MATCHES_PLAYED), sum(MATCHES_WON),sum(MATCHES_LOST) 
from ipl_team_standings join ipl_team using (team_id) 
group by TEAM_ID;

# 7.	Display the bowlers for the Mumbai Indians team.

select TEAM_NAME, PLAYER_NAME, PLAYER_ROLE 
from ipl_team_players a 
join ipl_team b using (team_id) 
join ipl_player c using (player_id)
where team_name = 'Mumbai Indians' and PLAYER_ROLE = 'Bowler';

# 8.	How many all-rounders are there in each team, Display the teams with more than 4 all-rounders in descending order.

select team_name, count(*) allrounders_cnt
from ipl_team_players a 
join ipl_team b using (team_id)
where PLAYER_ROLE = 'All-rounder'
group by team_id
having count(*) > 4
order by count(*) desc;

# 9.	Write a query to get the total bidders points for each bidding status of those bidders who bid on CSK when it won the match in M. Chinnaswamy Stadium bidding year-wise.
# 		Note the total bidders’ points in descending order and the year is bidding year.
# 		Display columns: bidding status, bid date as year, total bidder’s points

create view winner as
(select *, if(toss_winner = 1, team_id1,team_id2) t_winner, if(match_winner = 1, team_id1,team_id2) m_winner from ipl_match);

select bid_status, year(bid_date), sum(total_points)
from ipl_bidder_details join ipl_bidder_points using (bidder_id)
join ipl_bidding_details using (bidder_id)
where bid_team = (select team_id from ipl_team where REMARKS = 'CSK') and
SCHEDULE_ID in (select SCHEDULE_ID from ipl_match_schedule 
					where STADIUM_ID = (select STADIUM_ID from ipl_stadium where STADIUM_NAME = 'M. Chinnaswamy Stadium')
                    and MATCH_ID in (select MATCH_ID from winner where m_winner = (select team_id from ipl_team where REMARKS = 'CSK')))
group by BID_STATUS,year(BID_DATE)
order by sum(TOTAL_POINTS) desc;


# 10.	Extract the Bowlers and All Rounders those are in the 5 highest number of wickets.
# 		Note 
#			1. use the performance_dtls column from ipl_player to get the total number of wickets
#			2. Do not use the limit method because it might not give appropriate results when players have the same number of wickets
#			3.	Do not use joins in any cases.
#			4.	Display the following columns teamn_name, player_name, and player_role.

with temp as(
select TEAM_NAME, PLAYER_NAME, PLAYER_ROLE, cast(substring(performance_dtls,position('Wkt-' in performance_dtls)+4,2) as decimal) Wickets 
from ipl_team_players a join ipl_player b using (player_id)
join ipl_team using (team_id)
where PLAYER_ROLE in ('Bowler','All-Rounder')
)
select * from
(select *, dense_rank()over(order by Wickets desc) rnk from temp) t
where rnk <= 5;

# 11.	show the percentage of toss wins of each bidder and display the results in descending order based on the percentage

-- The view 'winner' created in question 9 is used for this answer
with temp as(
select bidder_id, count(*) wincnt 
from ipl_bidder_points join ipl_bidding_details using (bidder_id) 
join ipl_match_schedule a using (schedule_id)
where bid_team = (select t_winner from winner b where b.MATCH_ID = a.MATCH_id)
group by BIDDER_ID
)
select bidder_id, ifnull(wincnt,0) wincnt,count(*),ifnull(wincnt,0)*100/count(*) win_pct
from ipl_bidding_details left join temp using (bidder_id) 
group by bidder_id order by win_pct desc;

# 12.	find the IPL season which has min duration and max duration.
# Output columns should be like the below:
# Tournment_ID, Tourment_name, Duration column, Duration

with t as(
select *, datediff(to_date,from_date) diff from ipl_tournament
)
select tournmt_id,tournmt_name, diff Duration_days from t
where diff in ((select min(diff) from t),(select max(diff) from t));

# 13.	Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total points in descending order and month-wise in ascending order.
# 		Note: Display the following columns:
# 		1.	Bidder ID, 2. Bidder Name, 3. bid date as Year, 4. bid date as Month, 5. Total points
# 		Only use joins for the above query queries.

select bidder_id, bidder_name, year(bid_date) yr, month(bid_date) mt, TOTAL_POINTS 
from ipl_bidder_points join ipl_bidding_details using (bidder_id) 
join ipl_bidder_details using (bidder_id)
where year(BID_DATE) = 2017 
group by bidder_id, year(bid_date),month(BID_DATE), TOTAL_POINTS
order by TOTAL_POINTS desc, month(bid_date) asc;

# 14.	Write a query for the above question using sub queries by having the same constraints as the above question.

with temp as
(select bidder_id, year(bid_date) yr, month(bid_date) mt from ipl_bidding_details
where year(bid_date) = 2017
group by bidder_id, year(bid_date),month(BID_DATE)
)
select bidder_id, 
(select bidder_name from  ipl_bidder_details a where a.BIDDER_id = temp.BIDDER_ID) bidder_name,
yr, mt,
(select total_points from ipl_bidder_points a where a.BIDDER_ID = temp.BIDDER_ID) total_points
from temp
order by total_points desc, mt asc;

# 15.	Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
# 		Output columns should be like:
# 		Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, Lowest_3_Bidders  --> columns contains name of bidder;

with cte as (
SELECT * FROM 
(SELECT BIDDER_ID,TOTAL_POINTS, 
ROW_NUMBER() OVER (Order BY TOTAL_POINTS ) as lowest_rnk,
ROW_NUMBER() OVER (Order BY TOTAL_POINTS desc) as highest_rnk
FROM IPL_BIDDER_POINTS) t
WHERE highest_rnk <=3 or lowest_rnk <=3 )

select cte.*,
if(highest_rnk <=3, bidder_name,null) Highest_3_Bidders,
if(lowest_rnk <=3, bidder_name,null) Lowest_3_Bidders 
from cte left join IPL_BIDDER_DETAILS ibd
on ibd.BIDDER_ID=cte.BIDDER_ID
order by highest_rnk;


--  Alternate Logic done by caluclating % of bids ion 2018 and estimating points gained by bidders in 2018 biding year

with temp as (select *, if(bid_status = 'Won', 1,0) chec, count(*)over(partition by bidder_id) tot from ipl_bidding_details)

select bidder_id, TOTAL_POINTS, ca bids_in_2018, tot total_bids,tots percent_of_bids_in_2018, est_pts Estimated_Points_for_2018, 
if(rnk <= 3,bidder_name,null) Highest_3_Bidders, 
if(rnk2 <= 3,bidder_name,null) Lowest_3_Bidders
from
(select bidder_id,sum(chec) ca,tot,total_points,sum(chec)/avg(tot) tots, TOTAL_POINTS*sum(chec)/avg(tot) est_pts, 
rank()over(order by TOTAL_POINTS*sum(chec)/avg(tot) asc) rnk2,
rank()over(order by TOTAL_POINTS*sum(chec)/avg(tot) desc) rnk
from ipl_bidder_points left join temp using(bidder_id) 
where year(bid_date) = 2018 group by bidder_id,TOTAL_POINTS) t
join ipl_bidder_details using (bidder_id)
where rnk <= 3 or rnk2 <= 3;

select * from ipl_bidder_points;

# 16.	Create two tables called Student_details and Student_details_backup.

create table Student_details (
Student_id int not null primary key, 
Student_name varchar(20) not null, 
mail_id varchar(20), 
mobile_no bigint
)
;
create table Student_details_backup as select * from Student_details;

create trigger insert_trig
after insert on Student_details
for each row
insert into Student_details_backup (Student_id,student_name,mail_id,mobile_no) 
values (new.Student_id,new.student_name,new.mail_id,new.mobile_no);
