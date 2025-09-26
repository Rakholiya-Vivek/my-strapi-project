// module.exports = ({ env }) => ({
//   host: env('HOST', '0.0.0.0'),
//   port: env.int('PORT', 1337),
//   app: {
//     keys: env.array('APP_KEYS'),
//   },
//   webhooks: {
//     populateRelations: env.bool('WEBHOOKS_POPULATE_RELATIONS', false),
//   },

//   allowedHosts: [
//     'my-strapi-project-vivek-alb-1419655971.ap-south-1.elb.amazonaws.com',
//   ],
// });

module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  app: {
    keys: env.array('APP_KEYS'),
  },
  webhooks: {
    populateRelations: env.bool('WEBHOOKS_POPULATE_RELATIONS', false),
  },
  settings: {
    cors: {
      enabled: true,
      origin: ['*'], // or restrict to specific domains
    },
  },
  allowedHosts: [
    'localhost',
    '127.0.0.1',
    'my-strapi-project-vivek-alb-1419655971.ap-south-1.elb.amazonaws.com'
  ],
});
