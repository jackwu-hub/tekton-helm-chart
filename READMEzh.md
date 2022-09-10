
实践了一下下面的想法，失败了，在执行添加阿里云helm仓库时，没有带上账号密码，添加helm仓库失败，
	暂时行不通，因为 这个行为 不是自己能够操控的。



因为jenkinsX中 tekton-pipeline使用的是这个 helm chart
    但是因为改不了镜像名称，拉取不到，所以复制了这个chat，修改后 上传到了阿里云的helm仓库，这样，我就可以把 jenkinsX中 的tekton-pipeline指向阿里云的helm仓库


tekton-pipeline目录中的 templates目录中的yaml文件不用自己写，
    使用make fetch脚本会自动生成出来 
        里面的Deployment的镜像使用的是 自己通过阿里云镜像仓库结合github构建出来的。


因为 仓库需要被 第三方应用拉取到，所以仓库是公开的。所以在 Makefile文件中，
    CHAR_REPO_NAMESPACE  ，REPO_USERNAME ，REPO_PASSWORD 用的是假数据。
    到时 使用 make 带上这些参数就行，如 , (在定义时使用了 ? 号的变量才能这么做)
        make  CHAR_REPO_NAMESPACE=bb REPO_USERNAME=cc REPO_PASSWORD=dd release
    
    但是又因为它是由 jenkinsX操控的，这里暂时写上真的，到时修改下jenkinsX中的镜像的参数，在执行make 时带上参数。


在jenkinsX生成的github仓库中，需要修改
    项目名/helmfiles/tekton-pipelines/helmfile.yaml 改的是helm仓库名和地址

    项目名/versionStream/charts/repositories.yml 改的是helm仓库名和地址

    项目名/versionStream/charts/cdf/tekton-pipeline/defaults.yaml  改的是 生成helm 仓库的 项目。

还要注意给这个新复制的仓库开一个和 当前所需要的tekton-pipeline 版本一样的分支，然后所有的修改都提交到这个分支里。比如我这里的版本是 v0.29.0, 

最好要对照你复制的这个仓库，默认分支改为 main 分支.
