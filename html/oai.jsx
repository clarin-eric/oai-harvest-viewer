// OAI DreamFactory API
var base = "http://192.168.99.100/api/v2/oai/_table/";
var key = "49b6352d3f5999db313bb4bf6d8a5980800b7264c8f8c23ffe432061ed0bb19d"

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
  handleClick: function() {
   // ReactDOM.unmountComponentAtNode(document.getElementById('records'));
    ReactDOM.render(
      <Records endpoint={this.props.id} />,
      document.getElementById('records')
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
    return {data: []};
  },
  loadRecords: function(endpoint) {
    $.ajax({
      url: base + "endpoint_record?" + $.param({include_count:true, filter:"endpoint="+endpoint+" AND metadataPrefix='cmdi'", api_key:key}),
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
  componentDidMount: function() {
    var endpoint = this.props.endpoint;
    if (endpoint)
      this.loadRecords(endpoint);
  },
  componentWillReceiveProps: function (nextProps) {
    var endpoint = nextProps.endpoint;
    if (endpoint)
      this.loadRecords(endpoint);
  },
  render: function() {
    var records = this.state.data.map(function(record) {
      return (
        <Record id={record.id} identifier={record.identifier}/>
      );
    });
    var filter = <Button>
      <Glyphicon glyph="filter" />
    </Button>;
          return <Col  xs={12} md={12} className="records" fill>
      <Panel fill>
        <span className="section col-xs-4">Records</span>
        <span className="col-xs-3">
          <Input className="filter" type="text" buttonAfter={filter} />
        </span>
        <span className="col-xs-5">
          <Pagination className="pagination" 
            prev
            next
            first
            last
            ellipsis
            items={20}
            maxButtons={5} />
        </span>
      </Panel>
      <Table striped bordered condensed hover fill>
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
  render: function() {
    return <tr>
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
    <Row id="endpoints" />
    <Row id="records" />
  </Grid>,
  document.getElementById('content')
);
ReactDOM.render(
  <Endpoints/>,
  document.getElementById('endpoints')
);
ReactDOM.render(
  <Records/>,
  document.getElementById('records')
);