-- 20260924000008 · Catálogo inicial de zonas (Maracaibo)
--
-- El apartado 3.3 del modelo lo advierte: el conductor elige de un catálogo, y
-- alguien tiene que cargarlo antes de que la app sirva para algo. Sin esto, la
-- pantalla de zonas sale vacía y el onboarding del conductor no se puede
-- probar.
--
-- ⚠️ PROVISIONAL. Son rectángulos aproximados trazados sobre el mapa, no los
-- límites oficiales de las parroquias. Sirven para desarrollar y demostrar;
-- antes de la entrega hay que reemplazarlos por polígonos reales. Es una de
-- las preguntas abiertas del apartado 11: quién carga el catálogo y con qué
-- criterio (¿parroquias oficiales, sectores como los nombra la gente, o los
-- recorridos que ya existen?).

-- Rectángulo a partir de dos esquinas, en orden antihorario.
create or replace function public.caja_zona(
  oeste double precision, sur   double precision,
  este  double precision, norte double precision
)
returns geography(Polygon, 4326)
language sql
immutable
as $$
  select st_geogfromtext(format(
    'POLYGON((%s %s, %s %s, %s %s, %s %s, %s %s))',
    oeste, sur,  este, sur,  este, norte,  oeste, norte,  oeste, sur
  ));
$$;

insert into public.zonas (nombre, municipio, poligono) values
  ('La Limpia',        'Maracaibo', public.caja_zona(-71.665, 10.670, -71.615, 10.700)),
  ('Circunvalación 2', 'Maracaibo', public.caja_zona(-71.665, 10.700, -71.610, 10.725)),
  ('Cuatricentenario', 'Maracaibo', public.caja_zona(-71.660, 10.725, -71.600, 10.755)),
  ('Las Delicias',     'Maracaibo', public.caja_zona(-71.645, 10.645, -71.610, 10.670)),
  ('5 de Julio',       'Maracaibo', public.caja_zona(-71.625, 10.645, -71.595, 10.670)),
  ('Tierra Negra',     'Maracaibo', public.caja_zona(-71.610, 10.665, -71.580, 10.695)),
  ('El Milagro',       'Maracaibo', public.caja_zona(-71.600, 10.650, -71.570, 10.700)),
  ('Sabaneta',         'Maracaibo', public.caja_zona(-71.650, 10.615, -71.610, 10.645)),
  ('El Amparo',        'Maracaibo', public.caja_zona(-71.690, 10.610, -71.650, 10.645)),
  ('Pomona',           'Maracaibo', public.caja_zona(-71.645, 10.590, -71.605, 10.618)),
  ('Los Haticos',      'Maracaibo', public.caja_zona(-71.625, 10.555, -71.585, 10.592)),
  ('San Francisco',    'San Francisco', public.caja_zona(-71.680, 10.510, -71.600, 10.560));

-- La caja se usa solo para la carga inicial; no hace falta conservarla.
drop function public.caja_zona(
  double precision, double precision, double precision, double precision
);
