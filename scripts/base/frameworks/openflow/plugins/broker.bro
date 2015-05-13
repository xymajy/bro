@load base/frameworks/openflow
@load base/frameworks/broker

module OpenFlow;

export {
	redef enum Plugin += {
		BROKER,
	};

	## Broker controller constructor.
	##
	## host: Controller ip.
	##
	## host_port: Controller listen port.
	##
	## topic: broker topic to send messages to.
	##
	## dpid: OpenFlow switch datapath id.
	##
	## Returns: OpenFlow::Controller record
	global broker_new: function(host: addr, host_port: port, topic: string, dpid: count): OpenFlow::Controller;

	redef record ControllerState += {
		## Controller ip.
		broker_host: addr &optional;
		## Controller listen port.
		broker_port: port &optional;
		## OpenFlow switch datapath id.
		broker_dpid: count &optional;
		## Topic to sent events for this controller to
		broker_topic: string &optional;
	};

	global broker_flow_mod: event(dpid: count, match: ofp_match, flow_mod: ofp_flow_mod);
	global broker_flow_clear: event(dpid: count);
}

function broker_describe(state: ControllerState): string
	{
	return fmt("Broker Plugin - %s:%d - DPID: %d", state$broker_host, state$broker_port, state$broker_dpid);
	}

function broker_flow_mod_fun(state: ControllerState, match: ofp_match, flow_mod: OpenFlow::ofp_flow_mod): bool
	{
	BrokerComm::event(state$broker_topic, BrokerComm::event_args(broker_flow_mod, state$broker_dpid, match, flow_mod));

	return T;
	}

function broker_flow_clear_fun(state: OpenFlow::ControllerState): bool
	{
	BrokerComm::event(state$broker_topic, BrokerComm::event_args(broker_flow_clear, state$broker_dpid));

	return T;
	}

# broker controller constructor
function broker_new(host: addr, host_port: port, topic: string, dpid: count): OpenFlow::Controller
	{
	BrokerComm::enable();
	BrokerComm::connect(cat(host), host_port, 1sec);

	return [$state=[$broker_host=host, $broker_port=host_port, $broker_dpid=dpid, $broker_topic=topic, $_plugin=OpenFlow::BROKER],
		$flow_mod=broker_flow_mod_fun, $flow_clear=broker_flow_clear_fun, $describe=broker_describe];
	}

