// OAI DreamFactory API
var base = "http://localhost/api/v2/oai/_table/";
var key = "00551c93af07a0e2c22628ad6214b9ab250cdfa82a5be2fc04789920e27a7170";
var endPagesize = 10;
var recPagesize = 1000;

// endpoints
var curationModule = "https://clarin.oeaw.ac.at/curate/#!ResultView/collection/";
var logDir         = "file:///Users/menzowi/Documents/Projects/OAI/harvester/logs";


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

var Endpoints = React.createClass({
  getInitialState: function() {
    return {data: [], meta: {count:0}, page:1, filter:""};
  },
  loadEndpoints: function(page,filter) {
    $(".endpoints .highlight").removeClass("highlight");
    if (page == null)
      page = 1;
    if (filter == null)
      filter = this.state.filter;
    var offset = (page - 1) * endPagesize;
    var f = "";
    if (filter != "")
      f = "name LIKE '%"+filter.replace(/'/g,"''")+"%'";
    $.ajax({
      url: base + "endpoint?" + $.param({offset:offset, limit:endPagesize, include_count:true, filter:f, api_key:key, order:'name ASC', related:'harvest_by_endpoint_harvest,endpoint_harvest_by_endpoint'}),
      dataType: 'json',
      cache: false,
      success: function(data) {
        this.setState({data: data.resource, meta:data.meta, page:page, filter:filter});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  },
  componentDidMount: function() {
    this.loadEndpoints(1,'');
  },
  handleSelect: function (event, selectedEvent) {
    var page = selectedEvent.eventKey;
    this.loadEndpoints(page);
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
        <Endpoint key={endpoint.id} id={endpoint.id} name={endpoint.name} type={endpoint.harvest_by_endpoint_harvest[0].type} url={endpoint.endpoint_harvest_by_endpoint[0].url}/>
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

var Endpoint = React.createClass({
  handleClick: function(me) {
    $(ReactDOM.findDOMNode(this)).addClass('highlight').siblings().removeClass('highlight');
    ReactDOM.render(
      <Records endpoint={this.props.id} />,
      document.getElementById('_records')
    );
    ReactDOM.render(
      <EndpointInfo endpoint={this.props.id} type={this.props.type} name={this.props.name} url={this.props.url}/>,
      document.getElementById('_endpointInfo')
    );
  },
  render: function() {
    return <tr key={this.props.id} onClick={this.handleClick}>
      <td>{this.props.name.replace(/_/g," ")}</td>
      <td>{this.props.type}</td>
    </tr>
  }
});

var EndpointInfo = React.createClass({
  getInitialState: function() {
    return {data: []};
  },
  loadInfo: function(endpoint) {
    $.ajax({
      url: base + "endpoint_info?" + $.param({api_key:key, filter:"id="+endpoint}),
      dataType: 'json',
      cache: false,
      success: function(data) {
        this.setState({data: data.resource[0]});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
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
    if (logDir != null)
      log = <tr key="log">
              <td>log</td>
              <td>
                <a href={logDir+"/"+this.props.type+"-"+this.props.type+"/"+this.props.name+".log"} target="log">log file</a>
              </td>
            </tr>;
    return <Table striped bordered condensed hover>
      <tbody>
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
/**/
var Records = React.createClass({
  getInitialState: function() {
    return {data: [], meta: {count:0}, page:1, endpoint:0, filter:""};
  },
  loadRecords: function(endpoint,page,filter) {
    $(".records .highlight").removeClass("highlight");
    if (page == null)
      page = 1;
    if (filter == null)
      filter = this.state.filter;
    var offset = (page - 1) * recPagesize;
    this.state.endpoint = endpoint;
    var f = "";
    if (filter != "")
      f = " AND (identifier LIKE '%"+filter.replace(/'/g,"''")+"%')";
    $.ajax({
    url: base + "endpoint_record?" + $.param({offset:offset, limit:recPagesize, include_count:true, filter:"(metadataPrefix='cmdi') AND (endpoint="+endpoint+")"+f , api_key:key}),
      dataType: 'json',
      cache: false,
      success: function(data) {
        this.setState({data:data.resource, meta:data.meta, page:page, endpoint:endpoint, filter:filter});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  },
  componentDidMount: function() {
    var endpoint = this.props.endpoint;
    if (endpoint)
      this.loadRecords(endpoint);
  },
  componentWillReceiveProps: function (nextProps) {
    var endpoint = nextProps.endpoint;
    if (endpoint) {
      this.loadRecords(endpoint,1,'');
    }
  },
  handleSelect: function (event, selectedEvent) {
    var page = selectedEvent.eventKey;
    this.loadRecords(this.state.endpoint,page);
  },
  handleFilter: function () {
    this.loadRecords(this.state.endpoint,1,this.refs.filterRecords.getValue());
  },
  handleChange: function() {
    this.setState({filter:this.refs.filterRecords.getValue()});
  },
  render: function() {
    var filter = this.state.filter;
    var page = this.state.page;
    var pages = Math.ceil(this.state.meta.count / recPagesize);
    var records = this.state.data.map(function(record) {
      return (
        <Record key={record.id} id={record.id} harvest={record.harvest} endpoint={record.endpoint} identifier={record.identifier}/>
      );
    });
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

var Record = React.createClass({
  handleClick: function(me) {
    $(ReactDOM.findDOMNode(this)).addClass('highlight').siblings().removeClass('highlight');
    ReactDOM.render(
      <RecordInfo endpoint={this.props.endpoint} identifier={this.props.identifier} harvest={this.props.harvest}/>,
      document.getElementById('_recordInfo')
    );
  },  
  render: function() {
    return <tr key={this.props.id} onClick={this.handleClick}>
      <td>{this.props.identifier}</td>
    </tr>
  }
});

var RecordInfo = React.createClass({
  getInitialState: function() {
    return {data: { resource: [ { metadataPrefix: "none"}] } };
  },
  loadInfo: function(harvest,endpoint,identifier) {
    $.ajax({
      url: base + "endpoint_record?" + $.param({api_key:key, filter:"(harvest="+harvest+") AND (endpoint="+endpoint+") AND (identifier='"+identifier+"')"}),
      dataType: 'json',
      cache: false,
      success: function(data) {
        this.setState({data: data});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
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
    var reps = this.state.data.resource.map(function(resource) {
      return (
        <tr key={resource.metadataPrefix}>
          <td>{resource.metadataPrefix}</td>
          <td>{resource.location}</td>
        </tr>
      );
    })
    return <Table striped bordered condensed hover>
      <tbody>
        {reps}
      </tbody>
    </Table>;
  }
});

ReactDOM.render(
  <Grid>
    <Row>
      <Col xs={12} md={12}>
        <PageHeader className="oai-header">
          <a href="http://www.clarin.eu/">
            <img src="static/clarin-logo.png" style={{height: 98 + 'px'}}/>
          </a>
          OAI Viewer
        </PageHeader>
      </Col>
    </Row>
    <div id="_endpoints" />
    <div id="_records" />
  </Grid>,
  document.getElementById('_content')
);
ReactDOM.render(
  <Endpoints/>,
  document.getElementById('_endpoints')
);
ReactDOM.render(
  <Records/>,
  document.getElementById('_records')
);
