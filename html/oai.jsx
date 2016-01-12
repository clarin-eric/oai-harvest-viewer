var base = "http://192.168.99.100/api/v2/oai/_table/";
var key = "49b6352d3f5999db313bb4bf6d8a5980800b7264c8f8c23ffe432061ed0bb19d"

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
    return <table>
      <thead>
        <tr>
          <th>Endpoints</th>
        </tr>
      </thead>
      <tbody>
        {endpoints}
      </tbody>
    </table>;
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
    return <table>
      <thead>
        <tr>
          <th>Records</th>
        </tr>
      </thead>
      <tbody>
        {records}
      </tbody>
    </table>;
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
  <Endpoints/>,
  document.getElementById('endpoints')
);
ReactDOM.render(
  <Records/>,
  document.getElementById('records')
);