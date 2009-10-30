class EJB::Example < EjbObject
  set_jndi_name             'SomeServices'
  set_bean_home_class       'SomeServicesHome'
  set_security_principal    'username'
  set_security_credentials  'password'
  set_provider_url          'ormi://host:port/SomeServices'
end
