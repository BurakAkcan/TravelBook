//
//  ListViewController.swift
//  TravelBook
//
//  Created by Burak AKCAN on 12.06.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    var titleList = [String]()
    var idList = [UUID]()
    var chosenTitle = ""
    var chosenId : UUID?
    
       
  

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(goAdd))

        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newData"), object: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return titleList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleList[indexPath.row]
        return cell
    }
    
    
    @objc func goAdd(){
        //Burayı ekelmeyi unutma! Diğer sayfada burayı kontrol ediyoruz çünkü
        chosenTitle = ""
        performSegue(withIdentifier: "map", sender: nil)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleList[indexPath.row]
        chosenId = idList[indexPath.row]
        performSegue(withIdentifier: "map", sender: nil)
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "map"{
           let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedId = chosenId
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = idList[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                if !(results.isEmpty) {
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "id") as? UUID{
                            if id == idList[indexPath.row]{
                                context.delete(result)
                                titleList.remove(at: indexPath.row)
                                idList.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do{
                                    try context.save()
                                }catch{
                                    print(error)
                                }
                                //Aranılan id bulunduysa döngüden hemen çıksın isteriz
                                break
                            }
                        }
                    }
                }
            }catch{
                print(error)
            }
            
        }
    }

 

}
extension ListViewController{
  @objc func getData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(request)
            if !(results.isEmpty){
                //Duplicate olmasın diye ekledik
                self.titleList.removeAll(keepingCapacity: false)
                self.idList.removeAll(keepingCapacity: false)
                for result in results as! [NSManagedObject] {
                  
                    if let title = result.value(forKey:"title") as? String{
                        self.titleList.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idList.append(id)
                    }
                    tableView.reloadData()
                }
            }
        }catch{
            print(error)
        }
    }
}
