// main.dart

// --- 1. Importaciones ---
// Importamos los paquetes y bibliotecas necesarios para que la app funcione.
// 'dart:convert' nos permite convertir (decodificar) las respuestas JSON de la API.
import 'dart:convert';
// 'package:flutter/material.dart' contiene todos los widgets y herramientas de la interfaz de usuario de Flutter.
import 'package:flutter/material.dart';
// 'package:http/http.dart' se usa para hacer peticiones HTTP (como GET y POST) a tu API.
import 'package:http/http.dart' as http;
// 'package:flutter_dotenv/flutter_dotenv.dart' nos permite cargar variables de entorno (como la URL de la API) de forma segura desde un archivo .env.
import 'package:flutter_dotenv/flutter_dotenv.dart';
// 'package:shared_preferences/shared_preferences.dart' es el paquete para guardar datos de forma local en el dispositivo.
import 'package:shared_preferences/shared_preferences.dart';

// --- 2. Modelo de Datos (Clase Efemeride) ---
// Definimos una clase simple para representar la estructura de un evento de efeméride.
// Esto hace que el código sea más limpio y fácil de entender que usar un Map.
// Ahora la clase incluye métodos para convertirla a y desde JSON, lo que es necesario para guardarla en SharedPreferences.
class Efemeride {
  final String titulo;
  final String evento;
  final String fecha; // Agregamos la fecha a nuestro modelo de datos.

  // El constructor de la clase. 'required' asegura que estos campos siempre se proporcionen.
  Efemeride({
    required this.titulo,
    required this.evento,
    required this.fecha,
  });

  // Método para convertir un objeto Efemeride a un Map JSON.
  // Esto es un paso de "serialización" (convertir un objeto a un formato que se pueda guardar).
  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'evento': evento,
        'fecha': fecha,
      };

  // Constructor que crea un objeto Efemeride desde un Map JSON.
  // Esto es "deserialización" (convertir el formato guardado de nuevo a un objeto).
  factory Efemeride.fromJson(Map<String, dynamic> json) {
    return Efemeride(
      titulo: json['titulo'] as String,
      evento: json['evento'] as String,
      fecha: json['fecha'] as String,
    );
  }
}

// --- 3. Gestión de Estado Global con Persistencia ---
// 'ValueNotifier' es una forma sencilla y eficiente de compartir datos entre diferentes widgets (pantallas).
// 'favoriteEventsNotifier' mantendrá la lista de efemérides que el usuario marque como favoritas.
// Al usarlo, la pantalla de favoritos se actualizará automáticamente cada vez que se añada o elimine un evento.
final ValueNotifier<List<Efemeride>> favoriteEventsNotifier = ValueNotifier([]);

// Clave para guardar y recuperar los datos de SharedPreferences. Es una buena práctica usar una constante.
const String favoritesKey = 'favorite_efemerides';

// --- 4. Funciones de Persistencia ---
// Función para guardar la lista de favoritos en el almacenamiento local.
// La palabra clave 'async' indica que es una función asíncrona, es decir, puede ejecutar operaciones que toman tiempo (como leer del disco duro) sin bloquear la interfaz de usuario.
Future<void> saveFavorites() async {
  // Obtenemos una instancia de SharedPreferences para trabajar con ella.
  final prefs = await SharedPreferences.getInstance();
  // Convierte la lista de objetos Efemeride a una lista de Mapas JSON usando el método 'toJson()' de nuestra clase.
  final jsonList = favoriteEventsNotifier.value.map((e) => e.toJson()).toList();
  // Convierte la lista de Mapas a una sola cadena JSON. 'jsonEncode' hace este trabajo.
  final jsonString = jsonEncode(jsonList);
  // Guarda la cadena JSON con la clave 'favoritesKey' en el almacenamiento local.
  await prefs.setString(favoritesKey, jsonString);
  print('✅ Favoritos guardados localmente.');
}

// Función para cargar la lista de favoritos al iniciar la app.
Future<void> loadFavorites() async {
  // Obtenemos una instancia de SharedPreferences.
  final prefs = await SharedPreferences.getInstance();
  // Intentamos obtener la cadena JSON guardada usando la clave.
  final jsonString = prefs.getString(favoritesKey);
  
  if (jsonString != null) {
    // Si encuentra datos guardados, los decodifica de JSON a una lista.
    final jsonList = jsonDecode(jsonString) as List;
    // Convierte cada Mapa JSON de la lista a un objeto Efemeride usando el constructor 'fromJson()'.
    final favorites = jsonList.map((e) => Efemeride.fromJson(e)).toList();
    // Actualiza el 'ValueNotifier' con la lista cargada. Esto hace que la UI se reconstruya.
    favoriteEventsNotifier.value = favorites;
    print('✅ Favoritos cargados del almacenamiento local.');
  }
}

// --- 5. Punto de Entrada de la Aplicación (main) ---
// La función 'main()' es el primer código que se ejecuta cuando la aplicación se inicia.
// La hacemos asíncrona para que pueda esperar a cargar las variables de entorno y los datos de favoritos.
Future<void> main() async {
  // Asegura que los 'widgets' de Flutter estén inicializados antes de cargar el .env o cualquier otro recurso.
  WidgetsFlutterBinding.ensureInitialized();
  // Carga las variables de entorno desde el archivo .env en la raíz del proyecto.
  await dotenv.load(fileName: ".env");
  // Llama a la función para cargar los favoritos guardados antes de construir la interfaz.
  await loadFavorites();
  // Ejecuta la aplicación principal (MyApp).
  runApp(const MyApp());
}

// --- 6. Widget Principal de la Aplicación (MyApp) ---
// 'MyApp' es el 'widget' raíz. Usamos un 'StatefulWidget' porque el estado de la barra de navegación (el índice seleccionado) cambiará.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 'State' de la clase MyApp.
  int _selectedIndex = 0; // Controla qué ícono del menú de navegación está seleccionado (0 = Home, 1 = Favoritos).
  late final PageController _pageController; // Controla el cambio de páginas en 'PageView'.

  @override
  void initState() {
    super.initState();
    // Inicializa el controlador de páginas.
    _pageController = PageController();
  }

  @override
  void dispose() {
    // Es importante liberar los recursos del controlador cuando el 'widget' se destruye para evitar fugas de memoria.
    _pageController.dispose();
    super.dispose();
  }

  // Función que se ejecuta cuando el usuario toca un ícono en la barra de navegación.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Actualiza el índice del ícono seleccionado.
    });
    // 'jumpToPage' cambia la vista a la página correspondiente sin animación.
    _pageController.jumpToPage(index); 
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Efemérides del Día',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: Scaffold(
        // 'body' contiene el contenido principal de la pantalla. 'PageView' permite deslizar entre las pantallas.
        body: PageView(
          controller: _pageController,
          // Al cambiar de página con un gesto, también actualizamos el índice.
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          // Lista de widgets (pantallas) que se mostrarán en cada página.
          children: const [
            EfemerideScreen(), // La pantalla de la efeméride principal.
            FavoritesScreen(), // La pantalla de la lista de favoritos.
          ],
        ),
        // 'bottomNavigationBar' es el widget que crea la barra de navegación en la parte inferior.
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            // Definimos los íconos y etiquetas para cada botón del menú.
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
          ],
          currentIndex: _selectedIndex, // Marca el ícono actual.
          selectedItemColor: Colors.blue[800], // Color del ícono seleccionado.
          onTap: _onItemTapped, // Llama a la función que maneja el toque.
        ),
      ),
    );
  }
}

// --- 7. PANTALLA PRINCIPAL (EFEMÉRIDES) ---
// 'StatefulWidget' porque el estado de la pantalla (título, evento, carga, etc.) cambiará.
class EfemerideScreen extends StatefulWidget {
  const EfemerideScreen({super.key});

  @override
  _EfemerideScreenState createState() => _EfemerideScreenState();
}

class _EfemerideScreenState extends State<EfemerideScreen> {
  // Variables que guardan el estado de la pantalla.
  String? titulo;
  String? evento;
  bool isLoading = true;
  String? errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Al iniciar la pantalla, llama a la API para obtener la efeméride de la fecha actual.
    fetchEfemeride(DateTime.now());
  }

  // Función para mostrar un selector de fecha y actualizar el estado de la aplicación.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Llama a la API con la nueva fecha seleccionada.
        fetchEfemeride(_selectedDate);
      });
    }
  }

  // Función que maneja el botón de "Me Gusta".
  void _toggleFavorite() {
    // Si no hay datos, no hace nada.
    if (titulo == null || evento == null) return;
    
    // Crea un nuevo objeto de tipo 'Efemeride' con los datos actuales.
    // La fecha se guarda como 'día/mes/año' para que sea fácil de mostrar.
    final currentEvent = Efemeride(
      titulo: titulo!,
      evento: evento!,
      fecha: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
    );

    // Verifica si el evento actual ya está en la lista de favoritos.
    final isAlreadyFavorite = favoriteEventsNotifier.value.any((item) => item.titulo == titulo);

    // Si ya es favorito, lo elimina. Si no, lo añade.
    if (isAlreadyFavorite) {
      // Elimina de la lista de favoritos.
      favoriteEventsNotifier.value.removeWhere((item) => item.titulo == titulo);
    } else {
      // Añade a la lista de favoritos. El operador '...' (spread) crea una nueva lista, lo que notifica a los 'listeners' del cambio.
      favoriteEventsNotifier.value = [...favoriteEventsNotifier.value, currentEvent];
    }
    // Llama a la función de guardado después de cada cambio en la lista.
    saveFavorites();
  }

  // Función asíncrona para hacer la petición a la API.
  Future<void> fetchEfemeride(DateTime date) async {
    // Actualiza el estado para mostrar el indicador de carga.
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Formatea la fecha para la URL (ej. 2025-08-19).
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      // Obtiene la URL base desde las variables de entorno. Usamos '??' para proporcionar un valor por defecto si la variable no se encuentra.
      final baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000';
      // Construye la URL completa con el parámetro de fecha.
      final url = '$baseUrl/efemeride?fecha=$formattedDate';

      final response = await http.get(Uri.parse(url));

      // Si la respuesta fue exitosa (código 200).
      if (response.statusCode == 200) {
        // Decodificamos la respuesta JSON del servidor.
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        
        // Si la respuesta es una lista y no está vacía, extrae el primer elemento.
        if (decodedData is List && decodedData.isNotEmpty) {
          final efemeride = decodedData[0];
          setState(() {
            titulo = efemeride['titulo'];
            evento = efemeride['evento'];
            isLoading = false;
          });
        } else {
          // Si no hay datos, muestra un mensaje.
          setState(() {
            isLoading = false;
            errorMessage = 'No se encontraron datos para esta fecha.';
          });
        }
      } else {
        // Manejo de errores del servidor (ej. 404, 500).
        final errorBody = utf8.decode(response.bodyBytes);
        setState(() {
          isLoading = false;
          errorMessage = 'Error del servidor (${response.statusCode}): $errorBody';
        });
      }
    } catch (e) {
      // Manejo de errores de conexión de red o de datos.
      setState(() {
        isLoading = false;
        errorMessage = 'Error de conexión o datos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Efemérides del Día'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Fila para el selector de fecha y el texto de la fecha.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Fecha seleccionada:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón del ícono de calendario para abrir el selector de fecha.
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botón para actualizar la efeméride.
              ElevatedButton.icon(
                onPressed: () => fetchEfemeride(_selectedDate),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar Efeméride'),
              ),
              const SizedBox(height: 24),
              
              // --- Contenido Dinámico de la Efeméride ---
              // El 'if' aquí es para mostrar el widget correcto dependiendo del estado.
              if (isLoading)
                const CircularProgressIndicator() // Muestra un círculo de carga mientras se obtienen los datos.
              else if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ) // Muestra un mensaje de error si algo sale mal.
              else if (titulo != null && evento != null)
                // 'ValueListenableBuilder' escucha los cambios en la lista de favoritos y reconstruye solo esta parte del árbol de widgets si la lista cambia.
                ValueListenableBuilder<List<Efemeride>>(
                  valueListenable: favoriteEventsNotifier,
                  builder: (context, favorites, child) {
                    // Verifica si el evento actual está en la lista de favoritos.
                    final isFavorite = favorites.any((item) => item.titulo == titulo);
                    
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Título del evento.
                                Flexible(
                                  child: Text(
                                    titulo!,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                                // Botón de "Me Gusta". El ícono cambia según el estado (relleno si es favorito, contorno si no).
                                IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : null,
                                  ),
                                  onPressed: _toggleFavorite, // Llama a la función que añade/elimina de favoritos.
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Fecha del evento.
                            Text(
                              'Fecha: ${"${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Descripción del evento.
                            Text(
                              evento!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                const Text('No se pudo cargar la efeméride.'), // Mensaje por defecto si no hay datos.
            ],
          ),
        ),
      ),
    );
  }
}

// --- 8. PANTALLA DE FAVORITOS ---
// Es 'StatelessWidget' porque no tiene estado interno que cambie.
// El estado (la lista de favoritos) se maneja con 'ValueNotifier'.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  // Función para eliminar un elemento de la lista de favoritos.
  void _removeFavorite(int index) {
    // Creamos una copia de la lista actual para poder modificarla. Esto es una buena práctica para evitar mutaciones directas.
    final updatedList = List<Efemeride>.from(favoriteEventsNotifier.value);
    // Eliminamos el elemento en la posición 'index'.
    updatedList.removeAt(index);
    // Asignamos la nueva lista al 'ValueNotifier', lo que notifica a la UI que cambie.
    favoriteEventsNotifier.value = updatedList;
    // Llama a la función de guardado después de eliminar.
    saveFavorites();
  }

  // Función para ordenar la lista de efemérides por fecha de mayor a menor.
  // Es crucial convertir las fechas de 'String' a un formato que se pueda comparar, como 'DateTime'.
  List<Efemeride> _sortFavorites(List<Efemeride> favorites) {
    // Creamos una copia de la lista para no modificar la original directamente.
    final sortedList = List<Efemeride>.from(favorites);
    // El método 'sort' reordena la lista. Le pasamos una función de comparación.
    sortedList.sort((a, b) {
      // Dividimos la fecha (ej. "19/08/2025") en partes: día, mes, año.
      final partsA = a.fecha.split('/');
      final partsB = b.fecha.split('/');
      
      // Creamos objetos 'DateTime' para comparar las fechas correctamente.
      // El formato es 'Año-Mes-Día', por eso los reordenamos.
      final dateA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
      final dateB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
      
      // 'compareTo' devuelve un número que indica el orden.
      // b.compareTo(a) ordena de mayor a menor (más reciente primero).
      return dateB.compareTo(dateA);
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Efemérides Favoritas'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ValueListenableBuilder<List<Efemeride>>(
        valueListenable: favoriteEventsNotifier,
        // El 'builder' se reconstruye cada vez que la lista de favoritos cambia.
        builder: (context, favorites, child) {
          // Si la lista está vacía, muestra un mensaje central.
          if (favorites.isEmpty) {
            return const Center(
              child: Text('No tienes efemérides favoritas aún.'),
            );
          }
          // Llama a la función de ordenamiento antes de construir la lista.
          final sortedFavorites = _sortFavorites(favorites);
          
          // Si hay favoritos, muestra una lista desplazable.
          return ListView.builder(
            itemCount: sortedFavorites.length, // Número de elementos en la lista.
            itemBuilder: (context, index) {
              final efemeride = sortedFavorites[index]; // Obtiene el evento en la posición actual.
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  // El título de la tarjeta será el título de la efeméride.
                  title: Text(efemeride.titulo),
                  // El subtítulo será la descripción del evento.
                  subtitle: Text(efemeride.evento),
                  // 'trailing' muestra un widget al final de la tarjeta. Usamos una fila para mostrar la fecha y el botón de eliminar.
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Usa el mínimo espacio horizontal.
                    children: [
                      // Muestra la fecha del evento.
                      Text(efemeride.fecha), 
                      const SizedBox(width: 8),
                      // Botón para eliminar el favorito.
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        // Al presionar el botón, llama a la función para eliminar el elemento.
                        onPressed: () => _removeFavorite(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}