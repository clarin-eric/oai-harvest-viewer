// react-bootstrap imports
var PageHeader = ReactBootstrap.PageHeader;
var Table = ReactBootstrap.Table;
var Panel = ReactBootstrap.Panel;
var Input = ReactBootstrap.Input;
var Button = ReactBootstrap.Button;
var Glyphicon = ReactBootstrap.Glyphicon;
var Pagination = ReactBootstrap.Pagination;
var Grid = ReactBootstrap.Grid;
var Row = ReactBootstrap.Row;
var Col = ReactBootstrap.Col;

// A list of Harvests
var Harvests = React.createClass({
  getInitialState: function() {
    return {data: [], meta: {count:0}, page:1, filter:""};
  },
  loadHarvests: function(page,filter) {
    $(".harvests .highlight").removeClass("highlight");
    var params = {
      order:'"when".desc'
    }
    if (page == null)
      page = 1;
    var offset = (page - 1) * harvPagesize;
    if (filter == null)
      filter = '';
    if (filter != "")
      params["type"]="like."+"*"+filter.replace(/'/g,"''").toLowerCase()+"*";
    $.ajax({
      url: base + "mv_harvest_info?" + $.param(params),
      dataType: 'json',
      cache: true,
      headers: {
        "Range-Unit": "items",
        "Range": ""+offset+"-"+(offset+harvPagesize-1),
        "Prefer": "count=exact"
      },
      success: function(d,status,xhr) {
        var cr = xhr.getResponseHeader('content-range');
        var cnt = cr.split("/")[1];
        this.setState({data: d, meta:{count:cnt}, page:page, filter:filter});
      }.bind(this),
      error: function(xhr, status, err) {
        console.log(this.url, status, err.toString());
      }
    });
  },
  componentDidMount: function() {
    this.loadHarvests(1,'');
  },
  handleFilter: function () {
    this.loadHarvests(1,this.refs.filterHarvests.getValue());
  },
  handleChange: function() {
    this.setState({filter:this.refs.filterHarvests.getValue()});
  },
  handleSelect: function (event, selectedEvent) {
    var page = selectedEvent.eventKey;
    console.log('clicked on paging button (Harvests)');
    this.loadHarvests(page);
  },
  render: function() {
    var filter = this.state.filter;
    var page = this.state.page;
    var pages = Math.ceil(this.state.meta.count / harvPagesize);
    var harvests = this.state.data.map(function(harvest) {
      return (
        <Harvest key={"h"+harvest.harvest_id} id={harvest.harvest_id} type={harvest.type} when={harvest.when} endpoints={harvest.endpoints} requests={harvest.requests} records={harvest.records}/>
      );
    });
    var glyph = <Button onClick={this.handleFilter}>
      <Glyphicon glyph="filter" />
    </Button>;
    return <div>
      <Row>
        <Col xs={12} md={12} className="harvestsHeader" fill>
          <Panel fill>
            <span className="section col-xs-4">Harvests</span>
            <span className="col-xs-4">
              <Input ref="filterHarvests" className="filter" type="text" hasFeedback placeholder="Enter harvest filter" value={this.state.filter} buttonAfter={glyph} onChange={this.handleChange}/>
            </span>
            <span className="col-xs-4">
              <Pagination className="pagination" 
                prev
                next
                first
                last
                ellipsis
                items={pages}
                maxButtons={5}
                activePage={page}
                onSelect={this.handleSelect}
              />
            </span>
          </Panel>
        </Col>
      </Row>
      <Row>      
        <Col xs={12} md={12} className="harvests" fill>
          <Table striped bordered condensed hover fill>
            <thead>
              <tr>
                <th>when</th>
                <th>harvest</th>
                <th>endpoints</th>
                <th>requests</th>
                <th>records</th>
             </tr>
            </thead>
            <tbody>
              {harvests}
              <tr key="totals">
                <th></th>
                <th></th>
                <th>{this.state.data.reduce(function(total,harvest) { return (total + Number(harvest.endpoints));},0)}</th>
                <th>{this.state.data.reduce(function(total,harvest) { return (total + Number(harvest.requests));},0)}</th>
                <th>{this.state.data.reduce(function(total,harvest) { return (total + Number(harvest.records));},0)}</th>
              </tr>
            </tbody>
          </Table>
        </Col>
      </Row>
    </div>;
  }
});

// A single Harvest
var Harvest = React.createClass({
  handleClick: function(me) {
    $(ReactDOM.findDOMNode(this)).addClass('highlight').siblings().removeClass('highlight');
    ReactDOM.render(
      <Endpoints harvest={this.props.id}/>,
      document.getElementById('_endpoints')
    );
  },
  render: function() {
    return <tr key={"h"+this.props.id} onClick={this.handleClick}>
      <td>{this.props.when}</td>
      <td>{this.props.type}</td>
      <td>{this.props.endpoints}</td>
      <td>{this.props.requests}</td>
      <td>{this.props.records}</td>
    </tr>
  }
});

// A list of Endpoints
var Endpoints = React.createClass({
  getInitialState: function() {
    return {data: [], meta: {count:0}, page:1, filter:""};
  },
  loadEndpoints: function(page,filter,harvest) {
    $(".endpoints .highlight").removeClass("highlight");
    if (page == null)
      page = 1;
    var offset = (page - 1) * endPagesize;
    var h = "";
    if (harvest)
        h = harvest;
    else if (this.props.harvest)
        h = this.props.harvest;
    var params = {
      harvest_id: 'eq.'+h, 
      order:'name.asc'
    }
    if (filter == null)
      filter = '';
    if (filter != "")
      params["name_lower"]="like."+"'*"+filter.replace(/'/g,"''").toLowerCase()+"*'";
    $.ajax({
      url: base + "mv_endpoint_info?" + $.param(params),
      headers: {
        "Range-Unit": "items",
        "Range": ""+offset+"-"+(offset+endPagesize-1),
        "Prefer": "count=exact"
      },
      dataType: 'json',
      cache: true,
      success: function(d,status,xhr) {
        var cr = xhr.getResponseHeader('content-range');
        var cnt = cr.split("/")[1];
        this.setState({data: d, meta:{count:cnt}, page:page, filter:filter});
      }.bind(this),
      error: function(xhr, status, err) {
        console.log(this.url, status, err.toString());
      }
    });
  },
  componentDidMount: function() {
    var harvest = this.props.harvest;
    if (harvest) {
      this.loadEndpoints(1,'',harvest);
    }
  },
  componentWillReceiveProps: function (nextProps) {
    var harvest = nextProps.harvest;
    if (harvest) {
      this.loadEndpoints(1,'',harvest);
    }
  },
  handleSelect: function (event, selectedEvent) {
    var page = selectedEvent.eventKey;
      console.log('clicked on paging button (Endpoint)');
    this.loadEndpoints(page,this.state.filter,this.props.harvest);
  },
  handleFilter: function () {
    this.loadEndpoints(1,this.refs.filterEndpoints.getValue());
  },
  handleChange: function() {
    this.setState({filter:this.refs.filterEndpoints.getValue()});
  },
  render: function() {
    var filter = this.state.filter;
    var page = this.state.page;
    var pages = Math.ceil(this.state.meta.count / endPagesize);
    var endpoints = this.state.data.map(function(endpoint) {
      return (
        <Endpoint key={"e"+endpoint.id} id={endpoint.id} harvest={endpoint.harvest_id} name={endpoint.name} location={endpoint.location} type={endpoint.type} url={endpoint.url}/>
      );
    });
    var glyph = <Button onClick={this.handleFilter}>
      <Glyphicon glyph="filter" />
    </Button>;
    return <div>
      <Row>
        <Col xs={12} md={12} className="endpointsHeader" fill>
          <Panel fill>
            <span className="section col-xs-4">Endpoints</span>
            <span className="col-xs-4">
              <Input ref="filterEndpoints" className="filter" type="text" hasFeedback placeholder="Enter endpoint filter" value={this.state.filter} buttonAfter={glyph} onChange={this.handleChange}/>
            </span>
            <span className="col-xs-4">
              <Pagination className="pagination" 
                prev
                next
                first
                last
                ellipsis
                items={pages}
                maxButtons={5}
                activePage={page}
                onSelect={this.handleSelect}
              />
            </span>
          </Panel>
        </Col>
      </Row>
      <Row>      
        <Col xs={8} md={8} className="endpoints" fill>
          <Table striped bordered condensed hover fill>
            <thead>
              <tr>
                <th>name</th>
                <th>type</th>
             </tr>
            </thead>
            <tbody>
              {endpoints}
            </tbody>
          </Table>
        </Col>
        <Col xs={4} md={4} className="endpointInfo" fill>
          <Panel header="Endpoint Info">
            <div id="_endpointInfo">Select an Endpoint</div>
          </Panel>
        </Col>
      </Row>
    </div>;
  }
});

// A single Endpoint
var Endpoint = React.createClass({
  handleClick: function(me) {
    $(ReactDOM.findDOMNode(this)).addClass('highlight').siblings().removeClass('highlight');
    ReactDOM.render(
      <Records endpoint={this.props.id} harvest={this.props.harvest} location={this.props.location} type={this.props.type}/>,
      document.getElementById('_records')
    );
    ReactDOM.render(
      <EndpointInfo endpoint={this.props.id} type={this.props.type} name={this.props.name} url={this.props.url}/>,
      document.getElementById('_endpointInfo')
    );
  },
  render: function() {
    return <tr key={"e"+this.props.id} onClick={this.handleClick}>
      <td>{this.props.name.replace(/_/g," ")}</td>
      <td>{this.props.type}</td>
    </tr>
  }
});

// Info on a single Endpoint
var EndpointInfo = React.createClass({
  getInitialState: function() {
    return {data: []};
  },
  loadInfo: function(id) {
    $.ajax({
      url: base + "mv_endpoint_info?" + $.param({"id":"eq."+id}),
      dataType: 'json',
      cache: true,
      success: function(data) {
        this.setState({data: data[0]});
        console.log('data: ' + JSON.stringify(this.state.data));
      }.bind(this),
      error: function(xhr, status, err) {
        console.log(this.url, status, err.toString());
      }
    });
  },
  componentDidMount: function() {
    var endpoint = this.props.endpoint;
    if (endpoint)
      this.loadInfo(endpoint);
  },
  componentWillReceiveProps: function (nextProps) {
    var endpoint = nextProps.endpoint;
    if (endpoint) {
      this.loadInfo(endpoint);
    }
  },
  render: function() {
    var log= "";
    if (outDir != null)
      log = <tr key="log">
              <td>log</td>
              <td>
                <a href={outDir+"/"+this.props.type+"/log/"+this.props.name+".log"} target="log">log file</a>
              </td>
            </tr>;
    return <Table striped bordered condensed hover>
      <tbody>
        <tr key="name">
          <td>name</td>
          <td>{this.props.name.replace(/_/g," ")}</td>
        </tr>
        <tr key="check">
          <td>check</td>
          <td>
            <a href={curationModule+"/"+this.props.name} target="oai">curation module</a>
          </td>
        </tr>
        {log}
        <tr key="records">
          <td>records</td>
          <td>{this.state.data.records}</td>
        </tr>
        <tr key="requests">
          <td>requests</td>
          <td>{this.state.data.requests}</td>
        </tr>
        <tr key="when">
          <td>when</td>
          <td>{this.state.data.when}</td>
        </tr>
        <tr key="where">
          <td>where</td>
          <td>
            <a href={this.props.url} target="oai">{this.props.url}</a>
          </td>
        </tr>
      </tbody>
    </Table>;
  }
});

// A list of Records
var Records = React.createClass({
  getInitialState: function() {
    return {data: [], meta: {count:0}, page:1, endpoint:0, harvest:0, filter:""};
  },
  loadRecords: function(endpoint,harvest,page,filter) {
    $(".records .highlight").removeClass("highlight");
    if (page == null)
      page = 1;
    var params = { }
    if (filter == null)
      filter = this.state.filter;
    var offset = (page - 1) * recPagesize;
    this.state.endpoint = endpoint;
    this.state.harvest = harvest;
    var f = "";
    if (filter == null)
      filter = '';
    if (filter != "")
      params["identifier"]="like."+"*"+filter.replace(/'/g,"''").toLowerCase()+"*";
      var url = base + "mv_endpoint_record?" +"endpoint=eq."+endpoint+"&harvest=eq."+harvest + "&" + $.param(params);
//    var url =  base + "/mv_endpoint_record?" + $.param({offset:offset, limit:recPagesize, include_count:true, filter:"(metadataPrefix='cmdi') AND (endpoint="+endpoint+") AND (harvest=.eq("+harvest+"))"+f , api_key:key};
          //
    $.ajax({
      url: url,
      headers: {
        "Range-Unit": "items",
        "Range": ""+offset+"-"+(offset+endPagesize-1),
        "Prefer": "count=exact"
      },
      dataType: 'json',
      cache: true,
      success: function(d,status,xhr) {
        var cr = xhr.getResponseHeader('content-range');
        var cnt = cr.split("/")[1];
        this.setState({data:d, meta:{count:cnt}, page:page, endpoint:endpoint, harvest:harvest, filter:filter});
      }.bind(this),
      error: function(xhr, status, err) {
        console.log(this.url, status, err.toString());
      }
    });
  },
  componentDidMount: function() {
    var endpoint = this.props.endpoint;
    var harvest = this.props.harvest;
    if (endpoint && harvest)
      this.loadRecords(endpoint,harvest);
  },
  componentWillReceiveProps: function (nextProps) {
    var endpoint = nextProps.endpoint;
    var harvest = nextProps.harvest;
    if (endpoint && harvest) {
      this.loadRecords(endpoint,harvest,1,'');
    }
  },
  handleSelect: function (event, selectedEvent) {
    var page = selectedEvent.eventKey;
    this.loadRecords(this.state.endpoint,this.state.harvest,page);
  },
  handleFilter: function () {
    this.loadRecords(this.state.endpoint,this.state.harvest,1,this.refs.filterRecords.getValue());
  },
  handleChange: function() {
    this.setState({filter:this.refs.filterRecords.getValue()});
  },
  render: function() {
    var filter = this.state.filter;
    var page = this.state.page;
    var pages = Math.ceil(this.state.meta.count / recPagesize);
    var records = this.state.data.map(function(type,location,record) {
      return (
        <Record key={"r"+record.id} id={record.id} harvest={record.harvest} type={type} endpoint={record.endpoint} identifier={record.identifier} location={location}/>
      );
    }.bind(null,this.props.type,this.props.location));
    var glyph = <Button onClick={this.handleFilter}>
      <Glyphicon glyph="filter" />
    </Button>;
    return <div>
      <Row>
        <Col xs={12} md={12} className="recordsHeader" fill>
          <Panel fill>
            <span className="section col-xs-4">Records</span>
            <span className="col-xs-4">
              <Input ref="filterRecords" className="filter" type="text" hasFeedback placeholder="Enter record filter" value={this.state.filter} buttonAfter={glyph} onChange={this.handleChange}/>
            </span>
            <span className="col-xs-4">
              <Pagination className="pagination" 
                prev
                next
                first
                last
                ellipsis
                items={pages}
                maxButtons={5}
                activePage={page}
                onSelect={this.handleSelect}
              />
            </span>
          </Panel>
        </Col>
      </Row>
      <Row>
        <Col xs={8} md={8} className="records" fill>
          <Table id="records" striped bordered condensed hover fill>
            <thead>
              <tr>
                <th>identifier</th>
              </tr>
            </thead>
            <tbody>
              {records}
            </tbody>
          </Table>
        </Col>
        <Col xs={4} md={4} className="recordInfo" fill>
          <Panel header="Record Info">
            <div id="_recordInfo">Select an Record</div>
          </Panel>
        </Col>
      </Row>
    </div>;
  }
});

// A single Record
var Record = React.createClass({
  handleClick: function(me) {
    $(ReactDOM.findDOMNode(this)).addClass('highlight').siblings().removeClass('highlight');
    ReactDOM.render(
      <RecordInfo endpoint={this.props.endpoint} identifier={this.props.identifier} harvest={this.props.harvest} type={this.props.type} location={this.props.location}/>,
      document.getElementById('_recordInfo')
    );
  },  
  render: function() {
    return <tr key={"r"+this.props.id} onClick={this.handleClick}>
      <td>{this.props.identifier}</td>
    </tr>
  }
});

// Info on a single Record
var RecordInfo = React.createClass({
  getInitialState: function() {
    return {data: { resource: [ { metadataPrefix: "none"}] } };
  },
  loadInfo: function(harvest,endpoint,identifier) {
      var url = base + "mv_endpoint_record?harvest=eq." + harvest + "&endpoint=eq." + endpoint + "&identifier=eq." + identifier;
      // + $.param({api_key:key, filter:"(harvest="+harvest+") AND (endpoint="+endpoint+") AND (identifier='"+identifier+"')"}),
    $.ajax({
      url: url,
      dataType: 'json',
      cache: true,
      success: function(d) {
        this.setState({data: {resource: d}});
      }.bind(this),
      error: function(xhr, status, err) {
        console.log(this.url, status, err.toString());
      }
    });
  },
  componentDidMount: function() {
    var harvest    = this.props.harvest;
    var endpoint   = this.props.endpoint;
    var identifier = this.props.identifier;
    if (harvest && endpoint && identifier)
      this.loadInfo(harvest,endpoint,identifier);
  },
  componentWillReceiveProps: function (nextProps) {
    var harvest    = nextProps.harvest;
    var endpoint   = nextProps.endpoint;
    var identifier = nextProps.identifier;
    if (harvest && endpoint && identifier)
      this.loadInfo(harvest,endpoint,identifier);
  },
  render: function() {
    var reps = this.state.data.resource.map(function(type,resource) {
      return (
        <tr key={resource.metadataPrefix}>
          <td>{resource.metadataPrefix}</td>
          <td>
            <a href={outDir+"/"+type+"/"+resource.location} target="oai">{(resource.metadataPrefix=='oai')?"request":"record"}</a>
          </td>
        </tr>
      );
    }.bind(null,this.props.type));
    return <Table striped bordered condensed hover>
      <tbody>
        <tr key="identifier">
          <td>identifier</td>
          <td>{this.props.identifier}</td>
        </tr>
        {reps}
      </tbody>
    </Table>;
  }
});

// "main"
ReactDOM.render(
  <Grid>
    <Row>
      <Col xs={12} md={12}>
        <PageHeader className="oai-header">
          <a href="http://www.clarin.eu/">
            <img src="static/clarin-logo.png" style={{height: 98 + 'px'}}/>
          </a>
          OAI Harvest Viewer
        </PageHeader>
      </Col>
    </Row>
    <div id="_harvests" />
    <div id="_endpoints" />
    <div id="_records" />
  </Grid>,
  document.getElementById('_content')
);
ReactDOM.render(
  <Harvests/>,
  document.getElementById('_harvests')
);
ReactDOM.render(
  <Endpoints/>,
  document.getElementById('_endpoints')
);
ReactDOM.render(
  <Records/>,
  document.getElementById('_records')
);
