//
//  ViewController.swift
//  TravelBook
//
//  Created by Burak AKCAN on 11.06.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate{
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenlongitude = Double()
  //DidSelectRow işlemi
    var selectedTitle:String = ""
    var selectedId:UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLongitude:Double?
    var annotationLatitude:Double?
    
    
    
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(SaveButton))
        mapView.delegate = self
        locationManager.delegate = self
        //desireAccuracy konumun doğruluğu
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //When in use Auth bu app i kullanırken konum al demek
        locationManager.requestWhenInUseAuthorization()
        //Kullanıcının yerini almaa başlamak
        locationManager.startUpdatingLocation()
        
        let gestureRecogView = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecogView)
        
        let gestureRecog = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gesture:)))
//Ne kadar uzun basarsa yakalasın gesture 2 sn basınca yakala demek
        gestureRecog.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecog)
        
        if selectedTitle != "" {
            //CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            //Filter
            let idString = selectedId!.uuidString
            //id si şu olan objeyi getir demektir aşağıdaki kod
            request.predicate = NSPredicate(format: "id = %@",idString)
            request.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(request)
                if !(results.isEmpty){
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        //Her şey düzgün bir şekilde geldi o zaman annotation oluşturabilirim
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude!, longitude: annotationLongitude!)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        // eğer daha önceden kayıt ettiğim yere listeden tıklarsam  yer değişmesin
                                        locationManager.stopUpdatingLocation()
                                        //işrateli yeri zoomlamak için
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
    
                    }
                }
            }catch{
                print(error)
            }
            
            
        }else{
            //Add New Data
        }
    }
    
    //Bu update edilen lokasyonları [CLLocation] içerisinde verir liste şeklinde verir
//CLLocation objesi enlem-boylam barındıran bir obje
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//Haritalarda biz hep  nelem ve boylamlarla çalışırz uygulama ilk açıldığında kullanıcıyı bir yere zoomlamak isteriz işte burada
//Bize array olarak gelen locationlardan ilk elemanın coordinate. diyerek enlem ve boylam değerlerini aldık
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
//Bunu view da zoomlamak için (Ne kadar küçük ise değer o kadar zoomlar)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
//Merkezi nereyi alıyım
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)

    }
    
    @objc func chooseLocation(gesture:UILongPressGestureRecognizer){
//gesture a ulaşıp bunun kendi özelliklerine erişebiliriz (gesture.state = .began ) başladı
        if gesture.state == .began {
            //Dokunulan noktayı alacağız şimdi
            
            let touchPoint = gesture.location(in: self.mapView) // hangi view ın noktlarını alacağım (self.mapView) deriz
            //Dokunulan koordinatları aşağıda alıyoruz
            let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            //Save etmek için latitude ve longitude  değerlerini almam lazım
            
            chosenlongitude = touchCoordinate.longitude
            chosenLatitude = touchCoordinate.latitude
            
            //pin oluşturma
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoordinate
            annotation.title = nameText.text //Anotasyona isim verdik
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
        }
        
    }


}

extension ViewController {
//Annotationı özelleştirmek için kullanırız pinin yanına bir buton ekleyeceğiz navigasyon işlemi için
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            //Kullanıcının yerini anitasyonla göstermek istemiyorum
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pinView == nil{
             pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //canShowOut baloncukla beraber extra bilgi gösterebildiğimiz yer
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.blue
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            pinView?.annotation = annotation
        }
        return pinView
        
    }
    //Pin e ekelenen butonun ne yapacağını gösterir
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //Önce seçilmiş bir yer var mı bunu kontrol etmeliyim
        if selectedTitle != ""{
            
            var newLocation = CLLocation(latitude: annotationLatitude!, longitude: annotationLongitude!)
            //Koordinatlar arası bağlantı sağlar
            CLGeocoder().reverseGeocodeLocation(newLocation) { (placeMarks, error) in
                if let placeMark = placeMarks {
                    if placeMark.count > 0 {
                        let newPlaceMark = MKPlacemark(placemark: placeMark[0])
                        let item = MKMapItem(placemark: newPlaceMark)
                        item.name = self.annotationTitle
                        //Aracla göster navigasyonu
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
        }
    }
    
    @objc func SaveButton(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        if let title = nameText.text,
           let comment = commentText.text{
            newPlace.setValue(title, forKey: "title")
            newPlace.setValue(comment, forKey: "subtitle")
            newPlace.setValue(chosenlongitude, forKey: "longitude")
            newPlace.setValue(chosenLatitude, forKey: "latitude")
            newPlace.setValue(UUID(), forKey: "id")
        }else{
            print("hata")
        }
       
        
        do{
            try context.save()
            print("succes")
            
        }catch{
            print(error)
            }
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
}
