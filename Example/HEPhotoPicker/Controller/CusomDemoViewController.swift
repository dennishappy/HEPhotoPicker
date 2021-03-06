//
//  CusomDemoViewController.swift
//  HEPhotoPicker_Example
//
//  Created by apple on 2018/11/6.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import HEPhotoPicker

class CusomDemoViewController: UIViewController {

    @IBOutlet weak var singleVideoView: UIView!
    
    @IBOutlet weak var singleImageView: UIView!
    @IBOutlet weak var pickerTypeSegment: UISegmentedControl!
    @IBOutlet weak var ascendingSwitch: UISwitch!
    @IBOutlet weak var videoSwitch: UISwitch!
    @IBOutlet weak var pickturSwitch: UISwitch!
    @IBOutlet weak var maxCountTextfield: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var accumulationSwitch: UISwitch!
    @IBOutlet weak var macCountOfVideoTextfield: UITextField!
    var selectedModel = [HEPhotoPickerListModel]()
    var visibleImages = [UIImage](){
        didSet{
            if oldValue != visibleImages{
                collectionView.reloadData()
            }
        }
    }
    
    var animator : HEPhotoBrowserAnimator = {
        let a = HEPhotoBrowserAnimator()
        a.transitionType = .modal
        return a
    }()
    var homeFrame = CGRect.zero
    override func viewDidLoad() {
        super.viewDidLoad()
        
 
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    @IBAction func imageSwitchClick(_ sender: UISwitch) {
       cleanSelectedBtnClick()
    }
    @IBAction func videoSwitchClick(_ sender: UISwitch) {
        cleanSelectedBtnClick()
    }
    @IBAction func segumentClick(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 2 :
           singleImageView.isHidden = true
           singleVideoView.isHidden = true
        case 3 :
           singleImageView.isHidden = true
           singleVideoView.isHidden = false
        default:
            singleImageView.isHidden = false
            singleVideoView.isHidden = false
        }
        cleanSelectedBtnClick()
    }
    
    @IBAction func selectorBtnClick(_ sender: Any) {
        self.view.endEditing(true)
        guard let str = maxCountTextfield.text,let count = Int(str) else {
            return
        }
        guard let videoStr = macCountOfVideoTextfield.text,let videoCount = Int(videoStr) else {
            return
        }
        
        let option = HEPhotoPickerOptions.init()
        option.ascendingOfCreationDateSort = ascendingSwitch.isOn
        
        option.singlePicture = pickturSwitch.isOn
        option.singleVideo = videoSwitch.isOn
        switch pickerTypeSegment.selectedSegmentIndex{
        case 0:
            option.mediaType = .image
        case 1:
            option.mediaType = .video
        case 2 :
            option.mediaType = .imageAndVideo
        case 3 :
            option.mediaType = .imageOrVideo
        default:
            fatalError()
        }
        if accumulationSwitch.isOn {
            option.defaultSelections = self.selectedModel
        }
        option.maxCountOfImage = count
        option.maxCountOfVideo = videoCount
        let picker = HEPhotoPickerViewController.init(delegate: self, options: option)
        
        
        hePresentPhotoPickerController(picker: picker)
        
    }
  func cleanSelectedBtnClick() {
        self.view.endEditing(true)
        selectedModel = [HEPhotoPickerListModel]()
        visibleImages = [UIImage]()
        
    }
}
extension CusomDemoViewController : HEPhotoPickerViewControllerDelegate{
    func pickerController(_ picker: UIViewController, didFinishPicking selectedImages: [UIImage],selectedModel:[HEPhotoPickerListModel]) {
        // 实现多次累加选择时，需要把选中的模型保存起来，传给picker
        self.selectedModel = selectedModel
        self.visibleImages = selectedImages
        picker.dismiss(animated: true, completion: nil)
    }
    func pickerControllerDidCancel(_ picker: UIViewController) {
        // 取消选择后的一些操作
    }
    
}
extension CusomDemoViewController : UICollectionViewDelegate,UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MasterCell.className, for: indexPath) as? MasterCell else {
            fatalError("unexpected cell in collection view")
        }

            
            cell.mediaModel = self.selectedModel[indexPath.row]
            
            cell.closeBtn.isHidden = false
            cell.closeBtnClickHandle = {[weak self] in
                self?.visibleImages.remove(at: indexPath.row)
                self?.selectedModel.remove(at: indexPath.row)
                self?.collectionView.reloadData()
            }

        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < selectedModel.count {
            animator.selIndex = indexPath
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            option.resizeMode = .none
            let size = CGSize.init(width: kScreenWidth, height: kScreenWidth)
            PHImageManager.default().requestImage(for:selectedModel[indexPath.row].asset ,
                                                  targetSize: size,
                                                  contentMode: .aspectFill,
                                                  options: option)
            { (image, nil) in
                let browser = BrowserViewController()
                browser.image = image!
                browser.imageIndex = indexPath
                browser.models = self.selectedModel
                browser.selectedModels = self.selectedModel
                self.animator.popDelegate = browser
                self.animator.pushDelegate = self
                browser.modalPresentationStyle = .custom
                
                browser.transitioningDelegate = self.animator
                self.present(browser, animated: true, completion: nil)
            }
        }
    }
    
}

extension CusomDemoViewController: HEPhotoBrowserAnimatorPushDelegate{
    
    public func imageViewRectOfAnimatorStart(at indexPath: IndexPath) -> CGRect {
        guard   let cell = collectionView.cellForItem(at: indexPath) as? MasterCell else{
            fatalError("unexpected cell in collection view")
        }
        homeFrame =   UIApplication.shared.keyWindow?.convert(cell.imageView.frame, from: cell.contentView) ?? CGRect.zero
        //返回具体的尺寸
        return homeFrame
    }
    public func imageViewRectOfAnimatorEnd(at indexPath: IndexPath) -> CGRect {
        //取出cell
        let cell = (collectionView.cellForItem(at: indexPath))! as! MasterCell
        //取出cell中显示的图片
        let image = cell.imageView.image
        let x: CGFloat = 0
        let width: CGFloat = kScreenWidth
        let height: CGFloat = width / (image!.size.width) * (image!.size.height)
        var y: CGFloat = 0
        if height < kScreenHeight {
            y = (kScreenHeight -   height) * 0.5
        }
        //计算方法后的图片的frame
        return CGRect(x: x, y: y, width: width, height: height)
        
    }
    public func imageView(at indexPath: IndexPath) -> UIImageView {
        //创建imageView对象
        let imageView = UIImageView()
        //取出cell
        let cell = (collectionView.cellForItem(at: indexPath))! as! MasterCell
        //取出cell中显示的图片
        let image = cell.imageView.image
        //设置imageView相关属性(拉伸模式)
        imageView.contentMode = .scaleAspectFit
        //设置图片
        imageView.image = image
        //将多余的部分裁剪
        imageView.clipsToBounds = true
        //返回图片
        return imageView
    }
}
