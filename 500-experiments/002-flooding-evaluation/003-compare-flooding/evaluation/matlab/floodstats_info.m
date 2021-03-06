%function floodstats_info(simple_filename, e2e_filename, prop_filename)

if (~exist('basedir'))
  basedir=''
  basedir='20131130/'
else
  basedir
end

load_data = 1;
placement = 1; % 0 or 1
suffix = '';

if ( load_data == 1 )
    if (placement == 0)
        suffix = '_rnd100';
        load(strcat(basedir,'flooding_pre_data_random.dat'),'-mat');
    else
        suffix = '_bb';
        load(strcat(basedir,'flooding_pre_data_multibox.dat'),'-mat');
    end
end

%ilename = 'result_flooding_info.dat';
simple_filename = strcat(basedir,'result_flooding_info.dat.simple');
e2e_filename = strcat(basedir,'result_flooding_info.dat.e2e');
prop_filename = strcat(basedir,'result_flooding_info.dat.unicast');
mpr_filename = strcat(basedir,'result_flooding_info.dat.mpr');
prob_filename = strcat(basedir,'result_flooding_info.dat.prob');

load_params;

NUM=1;

TXNODE=2;
RXNODE=3;
SRCNODE=4;
PACKETSIZE=5;


PACKETCOUNT=11;
FLOODINGID=12;
NOFWD=13;

NOSENT=14;   % <<----- number of sent copies (MAC)

FWD=15;
RESP=16;
FORRESP=17;
RXACKED=18;
RCVCNT=19;


FWDDONE=20;
FWDSUCC=21;
FINRESP=22;
TIME=23;     % <<------ RX time of the first pkt of the flooding

SIM=24;
UNICASTSTRATEGY=25;
PLACEMENT=26;
UNICAST_PRESELECTION_STRATEGY=27;
UNICAST_REJECTONEMPTYCS=28;
UNICAST_UCASTPEERMETRIC=29;
FLOODING_NET_RETRIES=30;


ALGORITHMID=31;
EXTRAINFO=32;
UNICASTSTRATEG=33;

COLLISIONS=34;
MACRETRIES=35;
NBMETRIC=36;
PIGGYBACK=37;
FRESP=38;
USEASS=39;
MAXDELAY=40;

SEED=41;
TXABORT=42;
FIXCS=43;
E2E=44;

%load('flooding_pre_data.dat','-mat');

params=[UNICASTSTRATEGY UNICAST_PRESELECTION_STRATEGY UNICAST_REJECTONEMPTYCS UNICAST_UCASTPEERMETRIC FLOODING_NET_RETRIES ALGORITHMID EXTRAINFO  MACRETRIES NBMETRIC PIGGYBACK FRESP USEASS MAXDELAY TXABORT FIXCS E2E ];

% UNICASTSTRATEGY
% UNICAST_PRESELECTION_STRATEGY
% UNICAST_REJECTONEMPTYCS
% UNICAST_UCASTPEERMETRIC
% FLOODING_NET_RETRIES
% ALGORITHMID (simple/mpr/prob)
% EXTRAINFO (Algo, e.g. probab)
% MACRETRIES
% NBMETRIC


%NAIVE
if (~exist('flood_sent'))

  data=load(simple_filename);

  % strategy
  net_retries_naive = unique(data(data(:,UNICASTSTRATEGY) == 0 & data(:,E2E) == 0,FLOODING_NET_RETRIES));

  net_retries_naive = [ 0 1 2 3 4 ]';

  src_nodes = unique(data(:,SRCNODE));
  params_value=unique(data(:,params),'rows');

  %%
  % NAIVE FLOODING
  flood_delays = [];
  flood_reach = [];
  flood_sent = [];
  flood_xlb = [];

  param_id = 1;

  for nn=1:size(net_retries_naive,1)
    flood_retries = net_retries_naive(nn);
    method = data(data(:,UNICASTSTRATEGY) == 0 & data(:,FLOODING_NET_RETRIES) == flood_retries & data(:,E2E) == 0,:);
    seeds = unique(method(:,SEED));
    flIds = unique(method(:,FLOODINGID));

    all_delays = [];
    reach = [];
    all_sent = [];

    flood_xlb = [ flood_xlb; [ 0 net_retries_naive(nn) 0 ]];

    for ff=1:size(flIds,1)
      for ss=1:size(seeds,1)
        for sn=1:size(src_nodes,1)
            fl_1 = method(method(:,FLOODINGID) == flIds(ff) & method(:,SEED) == seeds(ss) & (method(:,SRCNODE) == src_nodes(sn)),:);

            %size(fl_1)
            %fl_1(:,[RXNODE TXNODE SRCNODE ])
            src_node = unique(fl_1(:,SRCNODE));
            assert(size(src_node,1) == 1 & size(src_node,2) == 1);

            start_time = min(fl_1(fl_1(:,RXNODE) == src_node,TIME));

            rx_times = fl_1(fl_1(:,RXNODE) ~= src_node, [RXNODE TIME]);
            %size(rx_times)
            rx_nodes = unique(rx_times(:,1));
            reach = [reach; size(rx_nodes,1)];

            delays = rx_times(:,2) - start_time;
            all_delays = [all_delays; delays];

            fl_1_sent_src = unique(fl_1(fl_1(:,SRCNODE) == fl_1(:,RXNODE),NOSENT));
            fl_1_sent_fwd = fl_1(fl_1(:,SRCNODE) == fl_1(:,TXNODE),NOSENT);

            %size(fl_1_sent_src)
            %size(fl_1_sent_fwd)

            all_sent = [all_sent; sum(fl_1_sent_fwd)];
        end
      end
    end

    size(all_sent)

    reach = reach + 1; % include src
    reach = reach / size(unique(method(:,RXNODE)),1);
    all_delays = all_delays * 1e3;

    flood_delays = [flood_delays; [all_delays zeros(size(all_delays,1),1) + param_id]];
    flood_reach = [flood_reach; [reach zeros(size(reach,1),1) + param_id]];
    flood_sent = [flood_sent; [all_sent zeros(size(all_sent,1),1) + param_id]];
    param_id = param_id + 1;
  end

  flood_param_id = param_id;
end

%%
% PROB FLOODING
if (~exist('prob_sent'))

  param_id = flood_param_id;

  data=load(prob_filename);

  prob_retries = unique(data(data(:,UNICASTSTRATEGY) == 0 & data(:,E2E) == 0, FLOODING_NET_RETRIES));
  prob_retries = [ 0 1 2 3 ]';

  prob_probs = unique(data(data(:,UNICASTSTRATEGY) == 0 & data(:,E2E) == 0, EXTRAINFO));
  prob_probs = sort(prob_probs,'descend');
  %prob_probs = [ 95 85 ]';

  src_nodes = unique(data(:,SRCNODE));

  prob_delays = [];
  prob_reach = [];
  prob_sent = [];
  prob_xlb = [];

  for pp=1:size(prob_probs,1)
  for nn=1:size(prob_retries,1)
    method = data(data(:,UNICASTSTRATEGY) == 0 & data(:,FLOODING_NET_RETRIES) == prob_retries(nn) & data(:,EXTRAINFO) == prob_probs(pp),:);
    seeds = unique(method(:,SEED));
    flIds = unique(method(:,FLOODINGID));

    all_delays = [];
    reach = [];
    all_sent = [];

    prob_xlb = [ prob_xlb; [ prob_probs(pp) 0 prob_retries(nn) ]];

    for ff=1:size(flIds,1)
      for ss=1:size(seeds,1)
        for sn=1:size(src_nodes,1)
            fl_1 = method(method(:,FLOODINGID) == flIds(ff) & method(:,SEED) == seeds(ss) & (method(:,SRCNODE) == src_nodes(sn)),:);

            %size(fl_1)
            %fl_1(:,[RXNODE TXNODE SRCNODE ])
            src_node = unique(fl_1(:,SRCNODE));
            assert(size(src_node,1) == 1 & size(src_node,2) == 1);

            start_time = min(fl_1(fl_1(:,RXNODE) == src_node,TIME));

            rx_times = fl_1(fl_1(:,RXNODE) ~= src_node, [RXNODE TIME]);
            %size(rx_times)
            rx_nodes = unique(rx_times(:,1));
            reach = [reach; size(rx_nodes,1)];

            delays = rx_times(:,2) - start_time;
            all_delays = [all_delays; delays];

            fl_1_sent_src = unique(fl_1(fl_1(:,SRCNODE) == fl_1(:,RXNODE),NOSENT));
            fl_1_sent_fwd = fl_1(fl_1(:,SRCNODE) == fl_1(:,TXNODE),NOSENT);

            %size(fl_1_sent_src)
            %size(fl_1_sent_fwd)

            all_sent = [all_sent; sum(fl_1_sent_fwd)];
        end
      end
    end

    size(all_sent)

    reach = reach + 1; % include src
    reach = reach / size(unique(method(:,RXNODE)),1);
    all_delays = all_delays * 1e3;

    prob_delays = [prob_delays; [all_delays zeros(size(all_delays,1),1) + param_id]];
    prob_reach = [prob_reach; [reach zeros(size(reach,1),1) + param_id]];
    prob_sent = [prob_sent; [all_sent zeros(size(all_sent,1),1) + param_id]];
    param_id = param_id + 1;
  end
  end

  prob_param_id = param_id;
end

%%
% E2E FLOODING
if (~exist('flood_e2e_sent'))

  param_id = prob_param_id;

  data=load(e2e_filename);

  e2e_retries_e2e = unique(data(data(:,UNICASTSTRATEGY) == 0 & data(:,E2E) ~= 0, E2E));
  e2e_retries_e2e = [ 1 2 3 4 ]';

  src_nodes = unique(data(:,SRCNODE));

  flood_e2e_delays = [];
  flood_e2e_reach = [];
  flood_e2e_sent = [];
  e2e_xlb = [];

  for nn=1:size(e2e_retries_e2e,1)
    flood_retries = e2e_retries_e2e(nn);
    method = data(data(:,UNICASTSTRATEGY) == 0 & data(:,E2E) == flood_retries,:);
    seeds = unique(method(:,SEED));
    flIds = unique(method(:,FLOODINGID));

    all_delays = [];
    reach = [];
    all_sent = [];

    e2e_xlb = [ e2e_xlb; [ 0 0 e2e_retries_e2e(nn) ]];

    for ff=1:(flood_retries+1):size(flIds,1)
      all_ids = [ flIds(ff):flIds(ff+flood_retries) ];
      for ss=1:size(seeds,1)
        for sn=1:size(src_nodes,1)
            fl_1 = method( ismember(method(:,FLOODINGID),all_ids) & method(:,SEED) == seeds(ss) & (method(:,SRCNODE) == src_nodes(sn)),:);

            %size(fl_1)
            %fl_1(:,[RXNODE TXNODE SRCNODE ])
            src_node = unique(fl_1(:,SRCNODE));
            assert(size(src_node,1) == 1 & size(src_node,2) == 1);

            start_time = min(fl_1(fl_1(:,RXNODE) == src_node,TIME));

            rx_times = fl_1(fl_1(:,RXNODE) ~= src_node, [RXNODE TIME]);
            %size(rx_times)
            rx_nodes = unique(rx_times(:,1));
            reach = [reach; size(rx_nodes,1)];

            min_rx_times = [];
            for r=1:size(rx_nodes)
              min_rx_times = [ min_rx_times; min(rx_times(rx_times(:,1) == rx_nodes(r),2)) ];
            end

            delays = min_rx_times - start_time;
            all_delays = [all_delays; delays];

            fl_1_sent_src = unique(fl_1(fl_1(:,SRCNODE) == fl_1(:,RXNODE),NOSENT));
            fl_1_sent_fwd = fl_1(fl_1(:,SRCNODE) == fl_1(:,TXNODE),NOSENT);

            all_sent = [all_sent; sum(fl_1_sent_fwd)];
        end
      end
    end

    size(all_sent)

    reach = reach + 1; % include src
    reach = reach / size(unique(method(:,RXNODE)),1);
    all_delays = all_delays * 1e3;

    flood_e2e_delays = [flood_e2e_delays; [all_delays zeros(size(all_delays,1),1) + param_id]];
    flood_e2e_reach = [flood_e2e_reach; [reach zeros(size(reach,1),1) + param_id]];
    flood_e2e_sent = [flood_e2e_sent; [all_sent zeros(size(all_sent,1),1) + param_id]];
    param_id = param_id + 1;
  end

  e2e_param_id = param_id;
end

%MPR
if (~exist('mpr_sent'))

  param_id = e2e_param_id;

  data=load(mpr_filename);

  % strategy
  net_retries_naive = unique(data(data(:,UNICASTSTRATEGY) == 0 & data(:,E2E) == 0,FLOODING_NET_RETRIES));

  net_retries_naive = [ 0 1 2 3 ]';

  src_nodes = unique(data(:,SRCNODE));
  params_value=unique(data(:,params),'rows');

  %%
  % NAIVE FLOODING
  mpr_delays = [];
  mpr_reach = [];
  mpr_sent = [];
  mpr_xlb = [];

  for nn=1:size(net_retries_naive,1)
    mpr_retries = net_retries_naive(nn);
    method = data(data(:,UNICASTSTRATEGY) == 0 & data(:,FLOODING_NET_RETRIES) == mpr_retries & data(:,E2E) == 0,:);
    seeds = unique(method(:,SEED));
    flIds = unique(method(:,FLOODINGID));

    all_delays = [];
    reach = [];
    all_sent = [];

    mpr_xlb = [ mpr_xlb; [ 0 net_retries_naive(nn) 0 ]];

    for ff=1:size(flIds,1)
      for ss=1:size(seeds,1)
        for sn=1:size(src_nodes,1)
            fl_1 = method(method(:,FLOODINGID) == flIds(ff) & method(:,SEED) == seeds(ss) & (method(:,SRCNODE) == src_nodes(sn)),:);

            %size(fl_1)
            %fl_1(:,[RXNODE TXNODE SRCNODE ])
            src_node = unique(fl_1(:,SRCNODE));
            assert(size(src_node,1) == 1 & size(src_node,2) == 1);

            start_time = min(fl_1(fl_1(:,RXNODE) == src_node,TIME));

            rx_times = fl_1(fl_1(:,RXNODE) ~= src_node, [RXNODE TIME]);
            %size(rx_times)
            rx_nodes = unique(rx_times(:,1));
            reach = [reach; size(rx_nodes,1)];

            delays = rx_times(:,2) - start_time;
            all_delays = [all_delays; delays];

            fl_1_sent_src = unique(fl_1(fl_1(:,SRCNODE) == fl_1(:,RXNODE),NOSENT));
            fl_1_sent_fwd = fl_1(fl_1(:,SRCNODE) == fl_1(:,TXNODE),NOSENT);

            %size(fl_1_sent_src)
            %size(fl_1_sent_fwd)

            all_sent = [all_sent; sum(fl_1_sent_fwd)];
        end
      end
    end

    size(all_sent)

    reach = reach + 1; % include src
    reach = reach / size(unique(method(:,RXNODE)),1);
    all_delays = all_delays * 1e3;

    mpr_delays = [mpr_delays; [all_delays zeros(size(all_delays,1),1) + param_id]];
    mpr_reach = [mpr_reach; [reach zeros(size(reach,1),1) + param_id]];
    mpr_sent = [mpr_sent; [all_sent zeros(size(all_sent,1),1) + param_id]];
    param_id = param_id + 1;
  end

  mpr_param_id = param_id;
end

%%
% PROPOSED METHOD
if (~exist('prop_sent'))

  param_id = mpr_param_id;

  data=load(prop_filename);

  net_retries_prop = unique(data(data(:,UNICASTSTRATEGY) == 4,FLOODING_NET_RETRIES));

  %filter
  net_retries_prop = [ 1 2 3 ]';

  prop_delays = [];
  prop_reach = [];
  prop_sent = [];

  prop_xlb = [];

  mac_retries = unique(data(:,MACRETRIES));

  for mm=1:size(mac_retries,1)
    mac_retry = mac_retries(mm);
    for nn=1:size(net_retries_prop,1)
        net_retry = net_retries_prop(nn);
        method = data(data(:,UNICASTSTRATEGY) == 4 & data(:,FLOODING_NET_RETRIES) == net_retry & data(:,MACRETRIES) == mac_retry,:);
        seeds = unique(method(:,SEED));
        flIds = unique(method(:,FLOODINGID));

        all_delays = [];
        reach = [];
        all_sent = [];

        prop_xlb = [ prop_xlb; [ (mac_retries(mm)-1) net_retries_prop(nn) 0 ]];

        for ff=1:size(flIds,1)
            for ss=1:size(seeds,1)
               for sn=1:size(src_nodes,1)
                fl_1 = method(method(:,FLOODINGID) == flIds(ff) & method(:,SEED) == seeds(ss) & (method(:,SRCNODE) == src_nodes(sn)),:);

                src_node = unique(fl_1(:,SRCNODE));
                assert(size(src_node,1) == 1 & size(src_node,2) == 1);

                start_time = min(fl_1(fl_1(:,RXNODE) == src_node,TIME));

                rx_times = fl_1(fl_1(:,RXNODE) ~= src_node, [RXNODE TIME]);
                rx_nodes = unique(rx_times(:,1));

                reach = [reach; size(rx_nodes,1)];

                delays = rx_times(:,2) - start_time;

                all_delays = [all_delays; delays];

                fl_1_sent_src = unique(fl_1(fl_1(:,SRCNODE) == fl_1(:,RXNODE),NOSENT));
                fl_1_sent_fwd = fl_1(fl_1(:,SRCNODE) == fl_1(:,TXNODE),NOSENT);

                %size(fl_1_sent_src)
                %size(fl_1_sent_fwd)

                all_sent = [all_sent; sum(fl_1_sent_fwd)];
             end
          end
        end

        reach = reach + 1; % include src
        reach = reach / size(unique(method(:,RXNODE)),1);
        all_delays = all_delays * 1e3;

        prop_delays = [prop_delays; [all_delays zeros(size(all_delays,1),1) + param_id]];
        prop_reach = [prop_reach; [reach zeros(size(reach,1),1) + param_id]];
        prop_sent = [prop_sent; [all_sent zeros(size(all_sent,1),1) + param_id]];
        param_id = param_id + 1;
    end
  end

  prop_param_id = param_id;

end

if (~exist('nonodes'))
  nonodes = length(unique(fl_1(:,RXNODE)));
  load_data = 0;
end

if ( load_data == 0 )
  save('flooding_pre_data.dat','flood_xlb', 'e2e_xlb', 'prop_xlb', 'mpr_xlb', 'prob_xlb', 'flood_delays', 'flood_e2e_delays', 'prop_delays', 'mpr_delays', 'prob_delays', 'flood_reach', 'flood_e2e_reach', 'prop_reach', 'mpr_reach', 'prob_reach','flood_sent', 'flood_e2e_sent','prop_sent', 'mpr_sent', 'prob_sent', 'nonodes');
end

%%
% plot

xlb=[ flood_xlb; prob_xlb; e2e_xlb; mpr_xlb; prop_xlb];
xlbs = cell(size(xlb,1),1);
for ii=1:size(xlb,1)
    xlbs{ii} = [int2str(xlb(ii,1)), '/', int2str(xlb(ii,2)), '/',int2str(xlb(ii,3)) ];
end

delays = [flood_delays; prob_delays; flood_e2e_delays; mpr_delays; prop_delays];
reach = [flood_reach; prob_reach; flood_e2e_reach; mpr_reach; prop_reach];
sent = [flood_sent; prob_sent; flood_e2e_sent; mpr_sent; prop_sent];

efficiency = sent;
efficiency(:,1) = efficiency(:,1)./(reach(:,1)*nonodes); % mac-tx per node, which recv the flood

% filter
idx = 1:33; %[1 4 8 9 10 11 15 16:27];

d_med_val = zeros(1,size(idx,2));
r_med_val = zeros(1,size(idx,2));
s_med_val = zeros(1,size(idx,2));
e_med_val = zeros(1,size(idx,2));

d_men_val = zeros(1,size(idx,2));
r_men_val = zeros(1,size(idx,2));
s_men_val = zeros(1,size(idx,2));
e_men_val = zeros(1,size(idx,2));

for ii=1:size(idx,2)
   d_med_val(ii) = median(delays(delays(:,2) == idx(ii),1));
   r_med_val(ii) = median(reach(reach(:,2) == idx(ii),1));
   s_med_val(ii) = median(sent(sent(:,2) == idx(ii),1));
   e_med_val(ii) = median(efficiency(efficiency(:,2) == idx(ii),1));

   d_men_val(ii) = mean(delays(delays(:,2) == idx(ii),1));
   r_men_val(ii) = mean(reach(reach(:,2) == idx(ii),1));
   s_men_val(ii) = mean(sent(sent(:,2) == idx(ii),1));
   e_men_val(ii) = mean(efficiency(efficiency(:,2) == idx(ii),1));
end

dmap = ismember(delays(:,2), idx);

% change
xlbs{1} ='naive';
% NET FL
xlbs{2} ='1';
xlbs{3} ='2';
xlbs{4} ='3';
xlbs{5} ='4';

% probabilistic FL
xlbs{6} ='0';
xlbs{7} ='1';
xlbs{8} ='2';
xlbs{9} ='3';
xlbs{10} ='0';
xlbs{11} ='1';
xlbs{12} ='2';
xlbs{13} ='3';

% E2E FL
xlbs{14} ='1';
xlbs{15} ='2';
xlbs{16} ='3';
xlbs{17} ='4';

% MPR FL
xlbs{18} ='0';
xlbs{19} ='1';
xlbs{20} ='2';
xlbs{21} ='3';

for ii=1:21
%    xlbs{ii} = '';
end

% Proposed FL
for ii=22:length(xlbs)
   xlbs{ii} = [' ', strrep(xlbs{ii}, '/0', '')]; 
end

xlbs2 = {};
for ii=1:length(xlbs)
   xlbs2{ii} = '';
end

dir = 'res/';

%%
h1=figure('Position', [100 100 700 500]);
boxplot(delays(dmap,1), delays(dmap,2), 'labels', xlbs2(idx));
flooding_caption(h1, xlbs(idx));
set(h1, 'Position', [100 100 1000 300]);

title('Delay');
ylabel('Delay in [ms]');
%xlabel('Flooding Schemes');%MAC/NET/E2E Retries');
grid on;
hold on
plot(d_men_val(idx), 'gd', 'MarkerFaceColor','green');

exportfig(gcf, [dir, 'delay', suffix ,'.eps'], 'LineStyleMap', [], 'Color', 'rgb');
rmap = ismember(reach(:,2), idx);

%subplot(1,3,2);
%%
h2=figure('Position', [100 100 700 500]);
boxplot(reach(rmap,1), reach(rmap,2), 'labels', xlbs2(idx));
flooding_caption(h2, xlbs(idx));
set(h2, 'Position', [100 100 1000 300]);

title('Reachbility');
ylabel('Reachbility in [%]');
%xlabel('Flooding Schemes');
grid on;
hold on
plot(r_men_val(idx), 'gd', 'MarkerFaceColor','green');

exportfig(gcf, [dir, 'reach', suffix ,'.eps'], 'LineStyleMap', [], 'Color', 'rgb');

smap = ismember(sent(:,2), idx);

%%
h3=figure('Position', [100 100 700 500]);
boxplot(sent(smap,1), sent(smap,2), 'labels', xlbs2(idx));
flooding_caption(h3, xlbs(idx));
set(h3, 'Position', [100 100 1000 300]);

%%
title('Efficiency');
ylabel('Total number of MAC transmissions');
%xlabel('Flooding Schemes');
grid on;
hold on
plot(s_men_val(idx), 'gd', 'MarkerFaceColor','green');

exportfig(gcf, [dir, 'sent', suffix ,'.eps'], 'LineStyleMap', [], 'Color', 'rgb');

emap = ismember(efficiency(:,2), idx);

%%
h4=figure('Position', [100 100 700 500]);
boxplot(efficiency(emap,1), efficiency(emap,2), 'labels', xlbs2(idx));
flooding_caption(h4, xlbs(idx));
set(h4, 'Position', [100 100 1000 300]);

%%
title('Efficiency');
ylabel('Total number of MAC TX per reached node');
%xlabel('Flooding Schemes');
grid on;
hold on
plot(e_men_val(idx), 'gd', 'MarkerFaceColor','green');

exportfig(gcf, [dir, 'efficiency', suffix ,'.eps'], 'LineStyleMap', [], 'Color', 'rgb');
