// OAI DreamFactory API
var base = "http://192.168.99.100/api/v2/oai/_table/";
var key = "49b6352d3f5999db313bb4bf6d8a5980800b7264c8f8c23ffe432061ed0bb19d";
var pagesize = 1000;

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
    return {data: []};
  },
  componentDidMount: function() {
    $.ajax({
      url: base + "endpoint?" + $.param({api_key:key}),
      dataType: 'json',
      cache: false,
      success: function(data) {
        this.setState({data: data.resource});
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  },
  render: function() {
    var endpoints = this.state.data.map(function(endpoint) {
      return (
        <Endpoint id={endpoint.id} name={endpoint.name}/>
      );
    });
    return <Col xs={12} md={12} className="endpoints" fill>
      <Panel fill>
        <span className="section col-xs-4">Endpoints</span>
      </Panel>
      <Table striped bordered condensed hover fill>
        <thead>
          <tr>
            <th>name</th>
          </tr>
        </thead>
        <tbody>
          {endpoints}
        </tbody>
      </Table>
    </Col>;
  }
});

var Endpoint = React.createClass({
  handleClick: function(me) {
    $(ReactDOM.findDOMNode(this)).addClass('highlight').siblings().removeClass('highlight');
    ReactDOM.render(
      <Records endpoint={this.props.id} />,
      document.getElementById('_records')
    );
  },
  render: function() {
    return <tr onClick={this.handleClick}>
      <td>{this.props.name}</td>
    </tr>
  }
});

var Records = React.createClass({
  getInitialState: function() {
    return {data: [], meta: {count:0}, page:1, endpoint:0, filter:""};
  },
  loadRecords: function(endpoint,page,filter) {
    $("#records .highlight").removeClass("highlight");
    if (page == null)
      page = 1;
    if (filter == null)
      filter = this.state.filter;
    var offset = (page - 1) * pagesize;
    this.state.endpoint = endpoint;
    var f = "";
    if (filter != "")
      f = " AND identifier LIKE '%"+filter.replace(/'/g,"''")+"%'";
    $.ajax({
    url: base + "endpoint_record?" + $.param({offset:offset, include_count:true, filter:"endpoint="+endpoint+" AND metadataPrefix='cmdi'"+f, api_key:key}),
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
    this.loadRecords(this.state.endpoint,1,this.refs.filter.getValue());
  },
  handleChange: function() {
    this.setState({filter:this.refs.filter.getValue()});
  },
  render: function() {
    var filter = this.state.filter;
    var page = this.state.page;
    var pages = Math.ceil(this.state.meta.count / pagesize);
    var records = this.state.data.map(function(record) {
      return (
        <Record id={record.id} identifier={record.identifier}/>
      );
    });
    var glyph = <Button onClick={this.handleFilter}>
      <Glyphicon glyph="filter" />
    </Button>;
    return <Col xs={12} md={12} className="records" fill>
      <Panel fill>
        <span className="section col-xs-4">Records</span>
        <span className="col-xs-3">
          <Input ref="filter" className="filter" type="text" hasFeedback placeholder="Enter record filter" value={filter} buttonAfter={glyph} onChange={this.handleChange}/>
        </span>
        <span className="col-xs-5">
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
    </Col>;
  }
});

var Record = React.createClass({
  handleClick: function(me) {
    $(ReactDOM.findDOMNode(this)).addClass('highlight').siblings().removeClass('highlight');
  },  
  render: function() {
    return <tr onClick={this.handleClick}>
      <td>{this.props.identifier}</td>
    </tr>
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
    <Row id="_endpoints" />
    <Row id="_records" />
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