import { useEffect, useState } from 'react'
import reactLogo from './assets/react.svg'
import clarinLogo from './assets/clarin-logo.png'
import viteLogo from '/vite.svg'
import './App.css'

import { Container, Row, Col, Navbar, Pagination, Table } from 'react-bootstrap';
import Form from 'react-bootstrap/Form';

function App() {
  return (
    <>
  <Container>
    <Row>
      <Col xs={12} md={12}>
        <Navbar className="oai-header">
        <h1 className="oai-header">
          <a href="http://www.clarin.eu/">
            <img src={clarinLogo} style={{height: 98 + 'px'}}/>
          </a>
          OAI Harvest Viewer
        </h1>
         OAI Harvest Viewer
        </Navbar>
      </Col>
    </Row>
    <div id="_harvests" >
       <Harvests/>
    </div>
    <div id="_endpoints" />
    <div id="_records" />
  </Container>
    </>
  );
}

// A list of Harvests
function Harvests()  {
    useEffect(() => {
        console.log('hello loadHarvests');
        loadHarvests(page, filter);
        console.log('bye loadHarvests');
    }, []);
  function loadHarvests(page,filter) {
    console.log('loadHarvests starts');
    $(".harvests .highlight").removeClass("highlight");
    var params = {
      order:'"when".desc'
    }
    // deze vier komen uit config.js
    var harvPagesize = 5;
    var endPagesize = 10;
    var recPagesize = 100;
    var base = "http://localhost:3000/";

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
          console.log('succes');
        var cr = xhr.getResponseHeader('content-range');
        var cnt = cr.split("/")[1];
        console.log('succes:' + cnt);
        setData(d);
        setMeta({count:cnt});
        setPage(page);
        setFilter(filter);
        console.log('succes: na sets');
//        this.setState({data: d, meta:{count:cnt}, page:page, filter:filter});
      },
      error: function(xhr, status, err) {
        console.log(url, status, err.toString());
      }
    });
          console.log('klaar')
};
 

    const [data,setData] = useState([]);
    const [meta,setMeta] = useState({});
    const [page,setPage] = useState(1);
    const [filter,setFilter] = useState('');
    const pages = 2;

    return ( <>
        <div>
        <Container>
      <Row>
        <Col xs={12} md={12} className="harvestsHeader" fill>
          <div>
            <span className="section col-xs-4">Harvests</span>
            <span className="col-xs-4">
              <Form.Control className="filter" type="text" hasFeedback placeholder="Enter harvest filter" />
            </span>
            <span className="col-xs-4">
              <Pagination className="pagination" 
                prev
                next
                first
                last
                ellipsis
                items={2}
                maxButtons={5}
                activePage={1}
                
              />
            </span>
          </div>
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
              <tr key="totals">
                <th></th>
                <th></th>
                <th></th>
            <th></th>
                <th></th>
              </tr>
            </tbody>
          </Table>
        </Col>
      </Row>
  </Container>
    </div>
    </>
    );
}




       
export default App
