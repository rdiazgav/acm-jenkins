const express = require('express');
const _ = require('lodash');

const app = express();
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  const message = _.join(['Hello', 'from', 'ACS', 'demo!'], ' ');
  res.send(`${message}\n`);
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});

